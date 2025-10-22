// models/score_data.dart
// Represents the complete data structure for staff notation rendering

import '../services/quantizer.dart';
import 'music_theory.dart';
import 'recording.dart';

/// Represents a measure in the score
class Measure {
  final int number; // 0-indexed
  final TimeSignature timeSignature;
  final List<ScoreElement> trebleElements; // Notes and rests for treble clef
  final List<ScoreElement> bassElements; // Notes and rests for bass clef

  const Measure({
    required this.number,
    required this.timeSignature,
    required this.trebleElements,
    required this.bassElements,
  });

  bool get isEmpty => trebleElements.isEmpty && bassElements.isEmpty;
}

/// Base class for things that appear in a measure
abstract class ScoreElement {
  final MusicalTime startTime;
  final RhythmicValue duration;

  const ScoreElement({
    required this.startTime,
    required this.duration,
  });

  double get beatPosition => startTime.beat;
}

/// A note or chord in the score
class ScoreNote extends ScoreElement {
  final List<NotePitch> pitches; // Multiple pitches = chord
  final int velocity;

  const ScoreNote({
    required super.startTime,
    required super.duration,
    required this.pitches,
    required this.velocity,
  });

  bool get isChord => pitches.length > 1;
}

/// A single pitch with its spelling and display information
class NotePitch {
  final int midiNote;
  final PitchSpelling spelling;
  final bool showAccidental; // Whether to display the accidental

  const NotePitch({
    required this.midiNote,
    required this.spelling,
    required this.showAccidental,
  });
}

/// A rest in the score
class ScoreRest extends ScoreElement {
  const ScoreRest({
    required super.startTime,
    required super.duration,
  });
}

/// Complete score data ready for rendering
class StaffNotationData {
  final Recording recording;
  final KeySignature keySignature;
  final TimeSignature timeSignature;
  final double beatsPerMinute;
  final List<Measure> measures;

  const StaffNotationData({
    required this.recording,
    required this.keySignature,
    required this.timeSignature,
    required this.beatsPerMinute,
    required this.measures,
  });

  /// Build staff notation data from a recording
  static StaffNotationData fromRecording(Recording recording) {
    final keySignature = KeySignature(
      sharps: recording.keySignatureSharps,
      isMinor: recording.keySignatureIsMinor,
    );

    final timeSignature = TimeSignature(
      numerator: recording.timeSignatureNumerator,
      denominator: recording.timeSignatureDenominator,
    );

    // Create quantizer
    final quantizer = Quantizer(
      recording: recording,
      beatsPerMinute: recording.beatsPerMinute,
      timeSignatureNumerator: recording.timeSignatureNumerator,
      timeSignatureDenominator: recording.timeSignatureDenominator,
    );

    // Quantize notes with auto-detected optimal grid resolution
    final quantizedNotes = quantizer.quantizeRecording(); // No gridResolution parameter = auto-detect

    // Split into treble and bass
    final split = quantizer.splitByClef(quantizedNotes);

    // Build measures
    final measures = _buildMeasures(
      split.treble,
      split.bass,
      quantizer,
      keySignature,
      timeSignature,
    );

    return StaffNotationData(
      recording: recording,
      keySignature: keySignature,
      timeSignature: timeSignature,
      beatsPerMinute: recording.beatsPerMinute,
      measures: measures,
    );
  }

  /// Build measure-by-measure data
  static List<Measure> _buildMeasures(
      List<QuantizedNote> trebleNotes,
      List<QuantizedNote> bassNotes,
      Quantizer quantizer,
      KeySignature keySignature,
      TimeSignature timeSignature,
      ) {
    if (trebleNotes.isEmpty && bassNotes.isEmpty) return [];

    // Find total number of measures needed
    final allNotes = [...trebleNotes, ...bassNotes];
    final maxMeasure = allNotes.isEmpty
        ? 0
        : allNotes.map((n) => n.startTime.measure).reduce((a, b) => a > b ? a : b);

    final measures = <Measure>[];

    for (int m = 0; m <= maxMeasure; m++) {
      // Get notes in this measure
      final trebleInMeasure = trebleNotes.where((n) => n.startTime.measure == m).toList();
      final bassInMeasure = bassNotes.where((n) => n.startTime.measure == m).toList();

      // Group into chords
      final trebleChords = quantizer.groupChords(trebleInMeasure);
      final bassChords = quantizer.groupChords(bassInMeasure);

      // Convert to score elements with rests
      final trebleElements = _buildScoreElements(trebleChords, keySignature, quantizer, m);
      final bassElements = _buildScoreElements(bassChords, keySignature, quantizer, m);

      measures.add(Measure(
        number: m,
        timeSignature: timeSignature,
        trebleElements: trebleElements,
        bassElements: bassElements,
      ));
    }

    return measures;
  }

  /// Build score elements (notes and rests) for a measure
  static List<ScoreElement> _buildScoreElements(
      List<List<QuantizedNote>> chords,
      KeySignature keySignature,
      Quantizer quantizer,
      int measureNumber,
      ) {
    final elements = <ScoreElement>[];

    if (chords.isEmpty) {
      // Whole measure rest
      final measureStart = measureNumber * quantizer.beatsPerMeasure;
      elements.add(ScoreRest(
        startTime: quantizer.beatsToMusicalTime(measureStart),
        duration: RhythmicValue.whole,
      ));
      return elements;
    }

    // Track which accidentals have been shown in this measure
    final shownAccidentals = <int, Accidental>{};

    // Add notes/chords with rests between them
    for (int i = 0; i < chords.length; i++) {
      final chord = chords[i];

      // Check if we need a rest before this chord
      if (i == 0) {
        // Check for rest at start of measure
        final measureStart = measureNumber * quantizer.beatsPerMeasure;
        final chordStart = chord.first.startTime.absoluteBeat;
        final gap = chordStart - measureStart;

        if (gap > 0.05) {
          final rests = quantizer.calculateRests([
            QuantizedNote(
              midiNote: 60,
              velocity: 0,
              startTime: quantizer.beatsToMusicalTime(measureStart),
              endTime: chord.first.startTime,
              duration: RhythmicValue.quarter,
            ),
            chord.first,
          ]);
          // Convert Rest to ScoreRest
          elements.addAll(rests.map((r) => ScoreRest(
            startTime: r.startTime,
            duration: r.duration,
          )));
        }
      } else {
        // Rest between previous chord and this one
        final prevChord = chords[i - 1];
        final prevEnd = prevChord.map((n) => n.endTime.absoluteBeat).reduce((a, b) => a > b ? a : b);
        final thisStart = chord.first.startTime.absoluteBeat;
        final gap = thisStart - prevEnd;

        if (gap > 0.05) {
          final rests = quantizer.calculateRests([
            QuantizedNote(
              midiNote: 60,
              velocity: 0,
              startTime: quantizer.beatsToMusicalTime(prevEnd),
              endTime: chord.first.startTime,
              duration: RhythmicValue.quarter,
            ),
            chord.first,
          ]);
          // Convert Rest to ScoreRest
          elements.addAll(rests.map((r) => ScoreRest(
            startTime: r.startTime,
            duration: r.duration,
          )));
        }
      }

      // Add the chord/note
      final pitches = chord.map((note) {
        final spelling = PitchSpelling.fromMidiNote(note.midiNote, keySignature);

        // Determine if we need to show the accidental
        bool showAccidental = false;

        if (spelling.accidental != Accidental.natural) {
          // Check if this accidental was already shown for this pitch class in this measure
          final pitchClass = note.midiNote % 12;

          if (shownAccidentals[pitchClass] != spelling.accidental) {
            showAccidental = true;
            shownAccidentals[pitchClass] = spelling.accidental;
          }
        } else {
          // Natural sign: show if we previously had an accidental for this pitch class
          final pitchClass = note.midiNote % 12;
          if (shownAccidentals.containsKey(pitchClass)) {
            showAccidental = true;
            shownAccidentals[pitchClass] = Accidental.natural;
          }
        }

        return NotePitch(
          midiNote: note.midiNote,
          spelling: spelling,
          showAccidental: showAccidental,
        );
      }).toList();

      // Sort pitches by MIDI note (lowest to highest)
      pitches.sort((a, b) => a.midiNote.compareTo(b.midiNote));

      elements.add(ScoreNote(
        startTime: chord.first.startTime,
        duration: chord.first.duration,
        pitches: pitches,
        velocity: chord.first.velocity,
      ));
    }

    return elements;
  }
}