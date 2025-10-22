// services/quantizer.dart
// Converts raw MIDI timestamps to musical time (beats, measures, note values)

import 'dart:math';
import '../models/note_event.dart';
import '../models/recording.dart';

/// Represents a position in musical time
class MusicalTime {
  final int measure; // 0-indexed
  final double beat; // 0-indexed within measure (0.0 = downbeat)
  final double absoluteBeat; // Total beats from start

  const MusicalTime({
    required this.measure,
    required this.beat,
    required this.absoluteBeat,
  });

  @override
  String toString() => 'M${measure + 1}:B${(beat + 1).toStringAsFixed(2)}';
}

/// Represents a rhythmic duration
enum RhythmicValue {
  whole,          // 4 beats
  half,           // 2 beats
  quarter,        // 1 beat
  eighth,         // 0.5 beats
  sixteenth,      // 0.25 beats
  thirtySecond,   // 0.125 beats

  dottedHalf,     // 3 beats
  dottedQuarter,  // 1.5 beats
  dottedEighth,   // 0.75 beats
  dottedSixteenth, // 0.375 beats

  halfTriplet,    // 1.333 beats (3 notes in 2 beats)
  quarterTriplet, // 0.667 beats (3 notes in 2 beats)
  eighthTriplet,  // 0.333 beats (3 notes in 1 beat)
}

extension RhythmicValueExtension on RhythmicValue {
  /// Duration in quarter note beats
  double get beats {
    switch (this) {
      case RhythmicValue.whole: return 4.0;
      case RhythmicValue.half: return 2.0;
      case RhythmicValue.quarter: return 1.0;
      case RhythmicValue.eighth: return 0.5;
      case RhythmicValue.sixteenth: return 0.25;
      case RhythmicValue.thirtySecond: return 0.125;
      case RhythmicValue.dottedHalf: return 3.0;
      case RhythmicValue.dottedQuarter: return 1.5;
      case RhythmicValue.dottedEighth: return 0.75;
      case RhythmicValue.dottedSixteenth: return 0.375;
      case RhythmicValue.halfTriplet: return 4.0 / 3.0;
      case RhythmicValue.quarterTriplet: return 2.0 / 3.0;
      case RhythmicValue.eighthTriplet: return 1.0 / 3.0;
    }
  }

  bool get isDotted => this == RhythmicValue.dottedHalf ||
      this == RhythmicValue.dottedQuarter ||
      this == RhythmicValue.dottedEighth ||
      this == RhythmicValue.dottedSixteenth;

  bool get isTriplet => this == RhythmicValue.halfTriplet ||
      this == RhythmicValue.quarterTriplet ||
      this == RhythmicValue.eighthTriplet;
}

/// A quantized note with musical time information
class QuantizedNote {
  final int midiNote;
  final int velocity;
  final MusicalTime startTime;
  final MusicalTime endTime;
  final RhythmicValue duration;
  final bool isTied; // True if note extends across measure boundary

  const QuantizedNote({
    required this.midiNote,
    required this.velocity,
    required this.startTime,
    required this.endTime,
    required this.duration,
    this.isTied = false,
  });

  double get durationInBeats => endTime.absoluteBeat - startTime.absoluteBeat;

  @override
  String toString() =>
      'Note $midiNote: $startTime → ${endTime.toString()} (${duration.name})';
}

class Quantizer {
  final Recording recording;
  final double beatsPerMinute;
  final int timeSignatureNumerator;
  final int timeSignatureDenominator;

  Quantizer({
    required this.recording,
    required this.beatsPerMinute,
    required this.timeSignatureNumerator,
    required this.timeSignatureDenominator,
  });

  /// Milliseconds per quarter note beat
  double get msPerBeat => 60000.0 / beatsPerMinute;

  /// Beats per measure (in quarter note units)
  double get beatsPerMeasure => (timeSignatureNumerator * 4.0) / timeSignatureDenominator;

  /// Convert milliseconds to absolute beat number
  double millisToBeats(int milliseconds) {
    return milliseconds / msPerBeat;
  }

  /// Convert absolute beat to musical time (measure + beat within measure)
  MusicalTime beatsToMusicalTime(double absoluteBeat) {
    final measure = (absoluteBeat / beatsPerMeasure).floor();
    final beatInMeasure = absoluteBeat % beatsPerMeasure;

    return MusicalTime(
      measure: measure,
      beat: beatInMeasure,
      absoluteBeat: absoluteBeat,
    );
  }

  /// Quantize a beat value to the nearest grid position
  /// Grid resolution determines the smallest note value (e.g., 0.25 = sixteenth notes)
  double quantizeBeat(double beat, {double gridResolution = 0.125}) {
    return (beat / gridResolution).round() * gridResolution;
  }

  /// Find the best rhythmic value for a duration
  RhythmicValue findBestRhythmicValue(double durationInBeats) {
    // List of all rhythmic values with their beat durations
    final values = RhythmicValue.values;

    // Find closest match
    RhythmicValue best = RhythmicValue.quarter;
    double minDifference = double.infinity;

    for (final value in values) {
      final difference = (value.beats - durationInBeats).abs();
      if (difference < minDifference) {
        minDifference = difference;
        best = value;
      }
    }

    return best;
  }

  /// Analyze note timing to find the best grid resolution
  double analyzeOptimalGridResolution() {
    if (recording.events.isEmpty) return 0.125;

    final noteOnsets = <double>[];
    for (final event in recording.events) {
      if (event.type == NoteEventType.on) {
        noteOnsets.add(millisToBeats(event.timestampMillis));
      }
    }

    if (noteOnsets.length < 2) return 0.125;

    // Find common inter-onset intervals
    final intervals = <double>[];
    for (int i = 1; i < noteOnsets.length; i++) {
      intervals.add(noteOnsets[i] - noteOnsets[i - 1]);
    }

    // Test different grid resolutions and find which one minimizes quantization error
    final testResolutions = [0.0625, 0.125, 0.25, 0.5]; // 32nd, 16th, 8th, quarter
    double bestResolution = 0.125;
    double minError = double.infinity;

    for (final resolution in testResolutions) {
      double totalError = 0.0;
      for (final onset in noteOnsets) {
        final quantized = (onset / resolution).round() * resolution;
        totalError += (onset - quantized).abs();
      }
      final avgError = totalError / noteOnsets.length;

      if (avgError < minError) {
        minError = avgError;
        bestResolution = resolution;
      }
    }

    return bestResolution;
  }

  /// Quantize all notes in the recording
  List<QuantizedNote> quantizeRecording({double? gridResolution}) {
    // Auto-detect optimal grid resolution if not provided
    final resolution = gridResolution ?? analyzeOptimalGridResolution();

    final quantizedNotes = <QuantizedNote>[];

    // Group note on/off events into pairs
    final Map<int, NoteEvent> activeNotes = {};

    for (final event in recording.events) {
      if (event.type == NoteEventType.on) {
        activeNotes[event.midiNote] = event;
      } else if (event.type == NoteEventType.off) {
        final startEvent = activeNotes.remove(event.midiNote);
        if (startEvent != null) {
          // Convert to beats
          final startBeats = millisToBeats(startEvent.timestampMillis);
          final endBeats = millisToBeats(event.timestampMillis);

          // Quantize
          final quantizedStart = quantizeBeat(startBeats, gridResolution: resolution);
          final quantizedEnd = quantizeBeat(endBeats, gridResolution: resolution);

          // Ensure minimum duration (at least grid resolution)
          final finalEnd = quantizedEnd > quantizedStart
              ? quantizedEnd
              : quantizedStart + resolution;

          // Convert to musical time
          final startTime = beatsToMusicalTime(quantizedStart);
          final endTime = beatsToMusicalTime(finalEnd);

          // Determine rhythmic value
          final durationBeats = finalEnd - quantizedStart;
          final rhythmicValue = findBestRhythmicValue(durationBeats);

          // Check if note crosses measure boundary (might need tie)
          final isTied = startTime.measure != endTime.measure;

          quantizedNotes.add(QuantizedNote(
            midiNote: startEvent.midiNote,
            velocity: startEvent.velocity,
            startTime: startTime,
            endTime: endTime,
            duration: rhythmicValue,
            isTied: isTied,
          ));
        }
      }
    }

    // Sort by start time
    quantizedNotes.sort((a, b) =>
        a.startTime.absoluteBeat.compareTo(b.startTime.absoluteBeat));

    return quantizedNotes;
  }

  /// Group notes that start at the same time (chords)
  List<List<QuantizedNote>> groupChords(List<QuantizedNote> notes) {
    if (notes.isEmpty) return [];

    final chords = <List<QuantizedNote>>[];
    final tolerance = 0.01; // 1% of a beat tolerance for "simultaneous"

    List<QuantizedNote> currentChord = [notes[0]];

    for (int i = 1; i < notes.length; i++) {
      final note = notes[i];
      final prevNote = currentChord.last;

      // Check if this note starts at roughly the same time as previous
      final timeDiff = (note.startTime.absoluteBeat - prevNote.startTime.absoluteBeat).abs();

      if (timeDiff < tolerance) {
        // Part of same chord
        currentChord.add(note);
      } else {
        // New chord
        chords.add(currentChord);
        currentChord = [note];
      }
    }

    // Add last chord
    if (currentChord.isNotEmpty) {
      chords.add(currentChord);
    }

    return chords;
  }

  /// Split notes into left hand (bass clef) and right hand (treble clef)
  /// Uses MIDI note 60 (Middle C) as the split point by default
  ({List<QuantizedNote> treble, List<QuantizedNote> bass}) splitByClef(
      List<QuantizedNote> notes, {
        int splitPoint = 60, // Middle C
      }) {
    final treble = <QuantizedNote>[];
    final bass = <QuantizedNote>[];

    for (final note in notes) {
      if (note.midiNote >= splitPoint) {
        treble.add(note);
      } else {
        bass.add(note);
      }
    }

    return (treble: treble, bass: bass);
  }

  /// Calculate rests needed between notes
  List<Rest> calculateRests(List<QuantizedNote> notes) {
    final rests = <Rest>[];

    for (int i = 0; i < notes.length - 1; i++) {
      final currentNote = notes[i];
      final nextNote = notes[i + 1];

      final gapStart = currentNote.endTime.absoluteBeat;
      final gapEnd = nextNote.startTime.absoluteBeat;
      final gapDuration = gapEnd - gapStart;

      // If there's a significant gap, add rest(s)
      if (gapDuration > 0.05) { // More than 5% of a beat
        rests.addAll(_fillGapWithRests(gapStart, gapDuration));
      }
    }

    return rests;
  }

  /// Fill a gap with appropriate rest values
  List<Rest> _fillGapWithRests(double startBeat, double duration) {
    final rests = <Rest>[];
    final startTime = beatsToMusicalTime(startBeat);

    // Common rest durations in descending order
    final restValues = [
      RhythmicValue.whole,
      RhythmicValue.half,
      RhythmicValue.quarter,
      RhythmicValue.eighth,
      RhythmicValue.sixteenth,
    ];

    double remaining = duration;
    double currentBeat = startBeat;

    while (remaining > 0.05) {
      // Find largest rest that fits
      RhythmicValue? selectedValue;

      for (final value in restValues) {
        if (value.beats <= remaining + 0.01) {
          selectedValue = value;
          break;
        }
      }

      if (selectedValue == null) break;

      rests.add(Rest(
        startTime: beatsToMusicalTime(currentBeat),
        duration: selectedValue,
      ));

      currentBeat += selectedValue.beats;
      remaining -= selectedValue.beats;
    }

    return rests;
  }
}

/// Represents a rest in the score
class Rest {
  final MusicalTime startTime;
  final RhythmicValue duration;

  const Rest({
    required this.startTime,
    required this.duration,
  });

  @override
  String toString() => 'Rest at ${startTime.toString()}: ${duration.name}';
}