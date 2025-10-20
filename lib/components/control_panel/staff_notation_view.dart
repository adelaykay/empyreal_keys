// components/control_panel/staff_notation_view.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../models/recording.dart';
import 'scrolling_score_widget.dart';

enum KeySignature {
  cMajor,    // No sharps/flats
  gMajor,    // 1 sharp (F#)
  dMajor,    // 2 sharps (F#, C#)
  aMajor,    // 3 sharps (F#, C#, G#)
  fMajor,    // 1 flat (Bb)
  bFlatMajor, // 2 flats (Bb, Eb)
}

enum NoteType {
  whole,      // 4 beats - hollow, no stem
  half,       // 2 beats - hollow, with stem
  quarter,    // 1 beat - filled, with stem
  eighth,     // 0.5 beat - filled, with stem and flag
  sixteenth,  // 0.25 beat - filled, with stem and 2 flags
}

class StaffNotationView extends StatelessWidget {
  final Recording recording;
  final double currentPosition;
  final double screenHeight;

  const StaffNotationView({
    super.key,
    required this.recording,
    required this.currentPosition,
    required this.screenHeight,
  });

  KeySignature _detectKeySignature(List<NoteBlock> notes) {
    // Count sharps and flats to guess key signature
    final pitchCounts = <int, int>{};
    for (final note in notes) {
      final pitchClass = note.midiNote % 12;
      pitchCounts[pitchClass] = (pitchCounts[pitchClass] ?? 0) + 1;
    }

    // Simple heuristic: most common accidentals
    final hasSharp = (pitchCounts[1] ?? 0) > 0 || (pitchCounts[6] ?? 0) > 0;
    final hasFlat = (pitchCounts[10] ?? 0) > 0 || (pitchCounts[3] ?? 0) > 0;

    if (!hasSharp && !hasFlat) return KeySignature.cMajor;
    if (hasSharp && pitchCounts[1]! > pitchCounts[6]!) return KeySignature.gMajor;
    if (hasFlat) return KeySignature.fMajor;

    return KeySignature.cMajor; // Default
  }

  @override
  Widget build(BuildContext context) {
    final notes = _buildNoteBlocks();
    final pixelsPerBeat = 80.0;
    final bpm = 120;
    final keySignature = _detectKeySignature(notes);

    final totalWidth = recording.events.isEmpty
        ? 100.0
        : (recording.events.last.timestamp.inMilliseconds / 1000.0) * (pixelsPerBeat * bpm / 60);

    return Container(
      margin: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: NeverScrollableScrollPhysics(),
              child: Transform.translate(
                offset: Offset(-currentPosition * pixelsPerBeat * bpm / 60 + 120, 0),
                child: CustomPaint(
                  size: Size(totalWidth + 300, screenHeight * 0.35),
                  painter: StaffPainter(
                    notes: notes,
                    pixelsPerBeat: pixelsPerBeat,
                    currentPosition: currentPosition,
                    bpm: bpm,
                    keySignature: keySignature,
                  ),
                ),
              ),
            ),

            Positioned(
              left: 120,
              top: 0,
              bottom: 0,
              child: Container(
                width: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.red.shade700.withOpacity(0.3),
                      Colors.red.shade700,
                      Colors.red.shade700.withOpacity(0.3),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<NoteBlock> _buildNoteBlocks() {
    final blocks = <NoteBlock>[];
    final Map<int, dynamic> activeNotes = {};

    for (final event in recording.events) {
      if (event.type.toString().contains('on')) {
        activeNotes[event.midiNote] = event;
      } else {
        final startEvent = activeNotes.remove(event.midiNote);
        if (startEvent != null) {
          final duration = (event.timestamp.inMilliseconds -
              startEvent.timestamp.inMilliseconds) / 1000.0;
          blocks.add(NoteBlock(
            midiNote: startEvent.midiNote,
            startTime: startEvent.timestamp.inMilliseconds / 1000.0,
            duration: duration,
            velocity: startEvent.velocity,
          ));
        }
      }
    }

    return blocks;
  }
}

class StaffPainter extends CustomPainter {
  final List<NoteBlock> notes;
  final double pixelsPerBeat;
  final double currentPosition;
  final int bpm;
  final KeySignature keySignature;

  StaffPainter({
    required this.notes,
    required this.pixelsPerBeat,
    required this.currentPosition,
    required this.bpm,
    required this.keySignature,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final staffTop = size.height * 0.35;
    final staffSpacing = 12.0;
    final measureWidth = pixelsPerBeat * 4;
    final staffStartX = 150.0; // Where notes begin after clef/signatures

    // Draw staff lines
    final linePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.5;

    for (int i = 0; i < 5; i++) {
      final y = staffTop + (i * staffSpacing);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Draw treble clef
    _drawTrebleClef(canvas, 15, staffTop + staffSpacing * 2);

    // Draw time signature (4/4)
    _drawTimeSignature(canvas, 70, staffTop, staffSpacing);

    // Draw key signature
    final keyWidth = _drawKeySignature(canvas, 95, staffTop, staffSpacing, keySignature);

    // Draw bar lines
    final barPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;

    // First bar line after clef/key signature
    canvas.drawLine(
      Offset(staffStartX - 10, staffTop),
      Offset(staffStartX - 10, staffTop + staffSpacing * 4),
      barPaint,
    );

    // Subsequent bar lines
    for (double x = staffStartX - 10 + measureWidth; x < size.width; x += measureWidth) {
      canvas.drawLine(
        Offset(x, staffTop),
        Offset(x, staffTop + staffSpacing * 4),
        barPaint,
      );
    }

    // Group notes by measure for better spacing
    final notesByMeasure = _groupNotesByMeasure(notes, measureWidth, bpm);

    // Draw notes with proper spacing
    for (final entry in notesByMeasure.entries) {
      final measureIndex = entry.key;
      final measureNotes = entry.value;

      // Calculate spacing within measure
      final measureStartX = staffStartX + (measureIndex * measureWidth);
      final availableWidth = measureWidth * 0.9; // Leave some margin

      for (int i = 0; i < measureNotes.length; i++) {
        final note = measureNotes[i];
        final staffPos = _getStaffPosition(note.midiNote);

        if (staffPos == null) continue;

        // Evenly space notes within measure
        final noteX = measureStartX + (i * availableWidth / measureNotes.length) + 20;
        final y = staffTop + (staffPos * staffSpacing / 2);

        final isActive = currentPosition >= note.startTime &&
            currentPosition < (note.startTime + note.duration);

        _drawNote(canvas, noteX, y, staffSpacing, staffPos, isActive, note.midiNote);
      }
    }
  }

  Map<int, List<NoteBlock>> _groupNotesByMeasure(List<NoteBlock> notes, double measureWidth, int bpm) {
    final beatsPerMeasure = 4;
    final secondsPerBeat = 60.0 / bpm;
    final secondsPerMeasure = beatsPerMeasure * secondsPerBeat;

    final Map<int, List<NoteBlock>> grouped = {};

    for (final note in notes) {
      final measureIndex = (note.startTime / secondsPerMeasure).floor();
      grouped.putIfAbsent(measureIndex, () => []).add(note);
    }

    return grouped;
  }

  int? _getStaffPosition(int midiNote) {
    // Treble clef staff positions (E4 to F5)
    const notePositions = {
      64: 0,  // E4
      65: 1,  // F4
      66: 1,  // F#4
      67: 2,  // G4
      68: 3,  // G#4
      69: 3,  // A4
      70: 4,  // A#4
      71: 4,  // B4
      72: 5,  // C5
      73: 6,  // C#5
      74: 6,  // D5
      75: 7,  // D#5
      76: 7,  // E5
      77: 8,  // F5
    };

    return notePositions[midiNote];
  }

  void _drawNote(Canvas canvas, double x, double y, double spacing, int staffPos, bool isActive, int midiNote) {
    // Calculate note duration in beats
    final note = notes.firstWhere((n) => n.midiNote == midiNote, orElse: () => notes.first);
    final beatsPerSecond = bpm / 60.0;
    final durationInBeats = note.duration * beatsPerSecond;

    // Determine note type based on duration
    final noteType = _getNoteType(durationInBeats);

    final notePaint = Paint()
      ..color = isActive ? Colors.green.shade700 : Colors.black
      ..style = PaintingStyle.fill;

    // Draw accidental if needed
    final accidental = _needsAccidental(midiNote, keySignature);
    if (accidental != null) {
      _drawAccidental(canvas, x - 18, y, accidental);
    }

    // Draw note head based on type
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(-0.3);

    if (noteType == NoteType.whole || noteType == NoteType.half) {
      // Hollow note head for whole and half notes
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 15, height: 10),
        Paint()
          ..color = isActive ? Colors.green.shade700 : Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    } else {
      // Filled note head for quarter and shorter
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 15, height: 10),
        notePaint,
      );
    }
    canvas.restore();

    // Draw stem (except for whole notes)
    if (noteType != NoteType.whole) {
      final stemPaint = Paint()
        ..color = isActive ? Colors.green.shade700 : Colors.black
        ..strokeWidth = 1.8;

      final stemUp = staffPos > 4;
      final stemLength = spacing * 3.5;

      if (stemUp) {
        canvas.drawLine(
          Offset(x + 6.5, y),
          Offset(x + 6.5, y - stemLength),
          stemPaint,
        );

        // Draw flag for eighth/sixteenth notes
        if (noteType == NoteType.eighth) {
          _drawFlag(canvas, x + 6.5, y - stemLength, stemUp, isActive);
        } else if (noteType == NoteType.sixteenth) {
          _drawFlag(canvas, x + 6.5, y - stemLength, stemUp, isActive);
          _drawFlag(canvas, x + 6.5, y - stemLength + 6, stemUp, isActive);
        }
      } else {
        canvas.drawLine(
          Offset(x - 6.5, y),
          Offset(x - 6.5, y + stemLength),
          stemPaint,
        );

        // Draw flag for eighth/sixteenth notes
        if (noteType == NoteType.eighth) {
          _drawFlag(canvas, x - 6.5, y + stemLength, stemUp, isActive);
        } else if (noteType == NoteType.sixteenth) {
          _drawFlag(canvas, x - 6.5, y + stemLength, stemUp, isActive);
          _drawFlag(canvas, x - 6.5, y + stemLength - 6, stemUp, isActive);
        }
      }
    }
  }

  NoteType _getNoteType(double beats) {
    if (beats >= 3.5) return NoteType.whole;
    if (beats >= 1.75) return NoteType.half;
    if (beats >= 0.875) return NoteType.quarter;
    if (beats >= 0.4375) return NoteType.eighth;
    return NoteType.sixteenth;
  }

  void _drawFlag(Canvas canvas, double x, double y, bool stemUp, bool isActive) {
    final flagPaint = Paint()
      ..color = isActive ? Colors.green.shade700 : Colors.black
      ..style = PaintingStyle.fill;

    final path = Path();
    if (stemUp) {
      path.moveTo(x, y);
      path.quadraticBezierTo(x + 10, y + 6, x + 10, y + 9);
      path.lineTo(x, y + 6);
    } else {
      path.moveTo(x, y);
      path.quadraticBezierTo(x - 10, y - 6, x - 10, y - 9);
      path.lineTo(x, y - 6);
    }
    path.close();
    canvas.drawPath(path, flagPaint);
  }

  String? _needsAccidental(int midiNote, KeySignature key) {
    final pitchClass = midiNote % 12;

    switch (key) {
      case KeySignature.cMajor:
        if (pitchClass == 1 || pitchClass == 6) return 'sharp';
        if (pitchClass == 10 || pitchClass == 3) return 'flat';
        break;
      case KeySignature.gMajor:
      // F# in key, show sharp for other accidentals
        if (pitchClass == 6) return null; // F# is in key
        if (pitchClass == 1) return 'sharp';
        if (pitchClass == 10 || pitchClass == 3) return 'flat';
        break;
      case KeySignature.fMajor:
      // Bb in key
        if (pitchClass == 10) return null; // Bb is in key
        if (pitchClass == 1 || pitchClass == 6) return 'sharp';
        if (pitchClass == 3) return 'flat';
        break;
      default:
        break;
    }
    return null;
  }

  void _drawAccidental(Canvas canvas, double x, double y, String type) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: type == 'sharp' ? '♯' : '♭',
        style: TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x, y - 10));
  }

  void _drawTrebleClef(Canvas canvas, double x, double y) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: '𝄞',
        style: TextStyle(fontSize: 65, color: Colors.black, fontFamily: 'serif'),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x, y - 35));
  }

  void _drawTimeSignature(Canvas canvas, double x, double top, double spacing) {
    final textStyle = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );

    var textPainter = TextPainter(
      text: TextSpan(text: '4', style: textStyle),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x, top + spacing * 0.3));

    textPainter = TextPainter(
      text: TextSpan(text: '4', style: textStyle),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x, top + spacing * 2.5));
  }

  double _drawKeySignature(Canvas canvas, double x, double top, double spacing, KeySignature key) {
    double width = 0;

    switch (key) {
      case KeySignature.gMajor:
        _drawAccidental(canvas, x, top + spacing * 2, 'sharp');
        width = 15;
        break;
      case KeySignature.dMajor:
        _drawAccidental(canvas, x, top + spacing * 2, 'sharp');
        _drawAccidental(canvas, x + 12, top + spacing * 0, 'sharp');
        width = 27;
        break;
      case KeySignature.fMajor:
        _drawAccidental(canvas, x, top + spacing * 2, 'flat');
        width = 15;
        break;
      case KeySignature.bFlatMajor:
        _drawAccidental(canvas, x, top + spacing * 2, 'flat');
        _drawAccidental(canvas, x + 12, top + spacing * 4, 'flat');
        width = 27;
        break;
      case KeySignature.cMajor:
      default:
        width = 0;
        break;
    }

    return width;
  }

  @override
  bool shouldRepaint(StaffPainter oldDelegate) => true;
}