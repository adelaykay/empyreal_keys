// components/notation/note_renderer.dart
// Helper class for rendering individual notes

import 'package:flutter/material.dart';
import '../../models/music_theory.dart';
import '../../models/score_data.dart';
import 'dart:math' as math;

import '../../services/quantizer.dart';

class NoteRenderer {
  final double staffLineSpacing;
  final double noteheadWidth;
  final double noteheadHeight;
  final double stemLength;

  NoteRenderer({
    this.staffLineSpacing = 9.0,
  })  : noteheadWidth = staffLineSpacing * 1.2,
        noteheadHeight = staffLineSpacing * 0.9,
        stemLength = staffLineSpacing * 3.5;

  /// Calculate Y position for a note on the staff
  /// Returns position relative to staff top, in half-spaces
  /// (0 = top line, 1 = space below, 2 = second line, etc.)
  double getNoteYPosition(NotePitch pitch, Clef clef) {
    // Map note names to their position on staff (in half-spaces from top)
    // For treble clef: F5 is on top line (0), A4 is in bottom space (7), etc.
    // For bass clef: A3 is on top line (0), C2 is in bottom space (7), etc.

    final noteName = pitch.spelling.noteName;
    final octave = pitch.spelling.octave;

    if (clef == Clef.treble) {
      // Treble clef: E5=top line (0), F5=above staff (-1)
      // Middle C (C4) is one ledger line below the staff (position 10)
      return _getTreblePosition(noteName, octave);
    } else {
      // Bass clef: G3=top line (0), A3=above staff (-1)
      // Middle C (C4) is one ledger line above the staff (position -2)
      return _getBassPosition(noteName, octave);
    }
  }

  double _getTreblePosition(NoteName note, int octave) {
    // Reference: Middle C (C4) = position 10 (one ledger below staff)
    // E5 (top line) = 0, D5 = 1, C5 = 2, B4 = 3, A4 = 4, G4 = 5, F4 = 6, E4 = 7, D4 = 8, C4 = 10

    final noteValue = _getNoteValue(note);
    final c4Position = 10.0; // Middle C position
    final positionFromC4 = c4Position - ((octave - 4) * 7 + noteValue);

    return positionFromC4;
  }

  double _getBassPosition(NoteName note, int octave) {
    // Reference: Middle C (C4) = position -2 (one ledger above staff)
    // G3 (top line) = 0, F3 = 1, E3 = 2, D3 = 3, C3 = 4, B2 = 5, A2 = 6, G2 = 7, F2 = 8

    final noteValue = _getNoteValue(note);
    final c4Position = -2.0; // Middle C position
    final positionFromC4 = c4Position - ((octave - 4) * 7 + noteValue);

    return positionFromC4;
  }

  int _getNoteValue(NoteName note) {
    // Return position offset within an octave (C=0, D=1, E=2, F=3, G=4, A=5, B=6)
    switch (note) {
      case NoteName.C: return 0;
      case NoteName.D: return 1;
      case NoteName.E: return 2;
      case NoteName.F: return 3;
      case NoteName.G: return 4;
      case NoteName.A: return 5;
      case NoteName.B: return 6;
    }
  }

  /// Draw a single note
  void drawNote(
      Canvas canvas, {
        required NotePitch pitch,
        required double x,
        required double staffY,
        required Clef clef,
        required RhythmicValue duration,
        required bool isActive, // Currently playing
      }) {
    final position = getNoteYPosition(pitch, clef);
    final y = staffY + (position * staffLineSpacing / 2);

    // Draw ledger lines if needed
    _drawLedgerLines(canvas, x, y, staffY, position);

    // Draw accidental if needed
    if (pitch.showAccidental) {
      _drawAccidental(canvas, pitch.spelling.accidental, x - noteheadWidth * 1.8, y);
    }

    // Determine if note should be filled
    final isFilled = _shouldNoteBeFilled(duration);

    // Draw notehead
    _drawNotehead(canvas, x, y, isFilled, isActive);

    // Draw stem (except for whole notes)
    if (duration != RhythmicValue.whole) {
      final stemUp = position > 4; // Stem up if note is below middle line
      _drawStem(canvas, x, y, stemUp);

      // Draw flags for eighth notes and shorter
      if (_needsFlag(duration)) {
        _drawFlag(canvas, x, y, stemUp, duration);
      }
    }
  }

  /// Draw a chord (multiple notes stacked vertically)
  void drawChord(
      Canvas canvas, {
        required List<NotePitch> pitches,
        required double x,
        required double staffY,
        required Clef clef,
        required RhythmicValue duration,
        required bool isActive,
      }) {
    if (pitches.isEmpty) return;

    // Sort pitches from lowest to highest
    final sortedPitches = List<NotePitch>.from(pitches)
      ..sort((a, b) => a.midiNote.compareTo(b.midiNote));

    // Calculate positions
    final positions = sortedPitches.map((p) => getNoteYPosition(p, clef)).toList();
    final avgPosition = positions.reduce((a, b) => a + b) / positions.length;

    // Draw all noteheads and accidentals
    for (int i = 0; i < sortedPitches.length; i++) {
      final pitch = sortedPitches[i];
      final position = positions[i];
      final y = staffY + (position * staffLineSpacing / 2);

      // Draw ledger lines
      _drawLedgerLines(canvas, x, y, staffY, position);

      // Draw accidental if needed (offset to avoid collision)
      if (pitch.showAccidental) {
        final accidentalX = x - noteheadWidth * (1.8 + (sortedPitches.length - i - 1) * 0.5);
        _drawAccidental(canvas, pitch.spelling.accidental, accidentalX, y);
      }

      // Draw notehead
      final isFilled = _shouldNoteBeFilled(duration);
      _drawNotehead(canvas, x, y, isFilled, isActive);
    }

    // Draw single stem for the chord
    if (duration != RhythmicValue.whole) {
      final stemUp = avgPosition > 4;
      final topY = staffY + (positions.first * staffLineSpacing / 2);
      final bottomY = staffY + (positions.last * staffLineSpacing / 2);

      _drawChordStem(canvas, x, topY, bottomY, stemUp);

      // Draw flag
      if (_needsFlag(duration)) {
        final flagY = stemUp ? topY : bottomY;
        _drawFlag(canvas, x, flagY, stemUp, duration);
      }
    }
  }

  /// Draw a rest symbol
  void drawRest(
      Canvas canvas, {
        required double x,
        required double staffY,
        required RhythmicValue duration,
      }) {
    final y = staffY + staffLineSpacing * 2; // Middle of staff

    final textStyle = TextStyle(
      fontSize: staffLineSpacing * 4,
      color: Colors.black,
      fontWeight: FontWeight.bold,
    );

    String restSymbol;
    switch (duration) {
      case RhythmicValue.whole:
        restSymbol = '𝄻'; // Whole rest
        break;
      case RhythmicValue.half:
        restSymbol = '𝄼'; // Half rest
        break;
      case RhythmicValue.quarter:
        restSymbol = '𝄽'; // Quarter rest
        break;
      case RhythmicValue.eighth:
        restSymbol = '𝄾'; // Eighth rest
        break;
      case RhythmicValue.sixteenth:
        restSymbol = '𝄿'; // Sixteenth rest
        break;
      default:
        restSymbol = '𝄽'; // Default to quarter rest
    }

    final textPainter = TextPainter(
      text: TextSpan(text: restSymbol, style: textStyle),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
  }

  void _drawNotehead(Canvas canvas, double x, double y, bool filled, bool isActive) {
    final paint = Paint()
      ..color = isActive ? Colors.green : Colors.black
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw oval notehead (slightly tilted)
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(-0.3); // Slight tilt
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: noteheadWidth,
        height: noteheadHeight,
      ),
      paint,
    );
    canvas.restore();

    // Draw glow for active notes
    if (isActive) {
      final glowPaint = Paint()
        ..color = Colors.green.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(x, y), noteheadWidth, glowPaint);
    }
  }

  void _drawStem(Canvas canvas, double x, double y, bool stemUp) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final stemX = stemUp ? x + noteheadWidth / 2 : x - noteheadWidth / 2;
    final startY = y;
    final endY = stemUp ? y - stemLength : y + stemLength;

    canvas.drawLine(Offset(stemX, startY), Offset(stemX, endY), paint);
  }

  void _drawChordStem(Canvas canvas, double x, double topY, double bottomY, bool stemUp) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final stemX = stemUp ? x + noteheadWidth / 2 : x - noteheadWidth / 2;
    final startY = stemUp ? bottomY : topY;
    final endY = stemUp ? topY - stemLength : bottomY + stemLength;

    canvas.drawLine(Offset(stemX, startY), Offset(stemX, endY), paint);
  }

  void _drawFlag(Canvas canvas, double x, double y, bool stemUp, RhythmicValue duration) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final stemX = stemUp ? x + noteheadWidth / 2 : x - noteheadWidth / 2;
    final flagY = stemUp ? y - stemLength : y + stemLength;

    // Simple flag representation (can be improved with curves)
    final flagPath = Path();
    if (stemUp) {
      flagPath.moveTo(stemX, flagY);
      flagPath.quadraticBezierTo(
        stemX + noteheadWidth * 0.8,
        flagY + staffLineSpacing * 0.5,
        stemX,
        flagY + staffLineSpacing * 1.2,
      );
    } else {
      flagPath.moveTo(stemX, flagY);
      flagPath.quadraticBezierTo(
        stemX - noteheadWidth * 0.8,
        flagY - staffLineSpacing * 0.5,
        stemX,
        flagY - staffLineSpacing * 1.2,
      );
    }

    canvas.drawPath(flagPath, paint);

    // Draw second flag for sixteenth notes
    if (duration == RhythmicValue.sixteenth) {
      final secondFlagPath = Path();
      if (stemUp) {
        secondFlagPath.moveTo(stemX, flagY + staffLineSpacing * 0.8);
        secondFlagPath.quadraticBezierTo(
          stemX + noteheadWidth * 0.8,
          flagY + staffLineSpacing * 1.3,
          stemX,
          flagY + staffLineSpacing * 2.0,
        );
      } else {
        secondFlagPath.moveTo(stemX, flagY - staffLineSpacing * 0.8);
        secondFlagPath.quadraticBezierTo(
          stemX - noteheadWidth * 0.8,
          flagY - staffLineSpacing * 1.3,
          stemX,
          flagY - staffLineSpacing * 2.0,
        );
      }
      canvas.drawPath(secondFlagPath, paint);
    }
  }

  void _drawAccidental(Canvas canvas, Accidental accidental, double x, double y) {
    String symbol;
    switch (accidental) {
      case Accidental.sharp:
        symbol = '♯';
        break;
      case Accidental.flat:
        symbol = '♭';
        break;
      case Accidental.natural:
        symbol = '♮';
        break;
      case Accidental.doubleSharp:
        symbol = '𝄪';
        break;
      case Accidental.doubleFlat:
        symbol = '𝄫';
        break;
    }

    final textStyle = TextStyle(
      fontSize: staffLineSpacing * 2.5,
      color: Colors.black,
      fontWeight: FontWeight.bold,
    );

    final textPainter = TextPainter(
      text: TextSpan(text: symbol, style: textStyle),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x, y - textPainter.height / 2));
  }

  void _drawLedgerLines(Canvas canvas, double x, double y, double staffY, double position) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw ledger lines above staff (position < 0)
    if (position < 0) {
      for (double p = -2; p >= position; p -= 2) {
        final lineY = staffY + (p * staffLineSpacing / 2);
        canvas.drawLine(
          Offset(x - noteheadWidth * 0.7, lineY),
          Offset(x + noteheadWidth * 0.7, lineY),
          paint,
        );
      }
    }

    // Draw ledger lines below staff (position > 8)
    if (position > 8) {
      for (double p = 10; p <= position; p += 2) {
        final lineY = staffY + (p * staffLineSpacing / 2);
        canvas.drawLine(
          Offset(x - noteheadWidth * 0.7, lineY),
          Offset(x + noteheadWidth * 0.7, lineY),
          paint,
        );
      }
    }
  }

  bool _shouldNoteBeFilled(RhythmicValue duration) {
    return duration != RhythmicValue.whole &&
        duration != RhythmicValue.half &&
        duration != RhythmicValue.dottedHalf;
  }

  bool _needsFlag(RhythmicValue duration) {
    return duration == RhythmicValue.eighth ||
        duration == RhythmicValue.sixteenth ||
        duration == RhythmicValue.dottedEighth;
  }
}

enum Clef { treble, bass }