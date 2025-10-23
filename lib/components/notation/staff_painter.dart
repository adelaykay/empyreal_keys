// components/notation/staff_painter.dart
// Draws musical staff notation

import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../models/music_theory.dart';
import '../../models/score_data.dart';
import 'note_renderer.dart';

class StaffPainter extends CustomPainter {
  final StaffNotationData scoreData;
  final double currentPosition; // Current playback position in seconds
  final double pixelsPerBeat;
  final double staffLineSpacing; // Space between staff lines

  StaffPainter({
    required this.scoreData,
    required this.currentPosition,
    this.pixelsPerBeat = 60.0,
    this.staffLineSpacing = 9.0,
  });

  // Convert beats to pixels
  double beatsToPixels(double beats) => beats * pixelsPerBeat;

  // Convert seconds to beats
  double secondsToBeats(double seconds) {
    return (seconds / 60.0) * scoreData.beatsPerMinute;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final currentBeat = secondsToBeats(currentPosition);

    // Calculate staff positioning
    final topStaffY = 40.0; // Leave room for top margin
    final stavesSpacing = staffLineSpacing * 9; // Space between treble and bass staves
    final bassStaffY = topStaffY + stavesSpacing;

    // Draw each measure
    double currentX = 80.0; // Left margin for clefs and key signature

    for (int i = 0; i < scoreData.measures.length; i++) {
      final measure = scoreData.measures[i];
      final measureWidth = _calculateMeasureWidth(measure);

      // Draw treble staff
      _drawStaff(
        canvas,
        x: currentX,
        y: topStaffY,
        width: measureWidth,
        isFirstMeasure: i == 0,
        clef: Clef.treble,
      );

      // Draw bass staff
      _drawStaff(
        canvas,
        x: currentX,
        y: bassStaffY,
        width: measureWidth,
        isFirstMeasure: i == 0,
        clef: Clef.bass,
      );

      // Draw measure bar
      _drawMeasureBar(canvas, currentX + measureWidth, topStaffY, bassStaffY);

      // Draw notes and rests in this measure
      _drawMeasureElements(
        canvas,
        measure: measure,
        measureX: currentX,
        trebleStaffY: topStaffY,
        bassStaffY: bassStaffY,
        currentBeat: currentBeat,
      );

      currentX += measureWidth;
    }

    // Draw playback cursor
    final cursorX = 80.0 + beatsToPixels(currentBeat);
    _drawPlaybackCursor(canvas, cursorX, topStaffY, bassStaffY);
  }

  /// Draw a 5-line staff
  void _drawStaff(
      Canvas canvas, {
        required double x,
        required double y,
        required double width,
        required bool isFirstMeasure,
        required Clef clef,
      }) {
    final linePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw 5 horizontal lines
    for (int i = 0; i < 5; i++) {
      final lineY = y + (i * staffLineSpacing);
      canvas.drawLine(
        Offset(x - 60, lineY),
        Offset(x + width, lineY),
        linePaint,
      );
    }

    // Draw clef on first measure only
    if (isFirstMeasure) {
      _drawClef(canvas, clef, x - 60, y + 5);
      _drawKeySignature(canvas, x - 25, y - 30, clef);
      _drawTimeSignature(canvas, x, y - 10);
    }
  }

  /// Draw clef symbol
  void _drawClef(Canvas canvas, Clef clef, double x, double y) {
    final textStyle = TextStyle(
      fontFamily: 'Bravura', // Music font - we'll use emojis/Unicode as fallback
      fontSize: staffLineSpacing * 5,
      color: Colors.black,
      fontWeight: FontWeight.normal,
    );

    final textSpan = TextSpan(
      text: clef == Clef.treble ? '𝄞' : '𝄢', // Unicode treble and bass clef
      style: textStyle,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Position adjustments for each clef
    final yOffset = clef == Clef.treble
        ? -staffLineSpacing * 1.5
        : staffLineSpacing * -1.5;

    textPainter.paint(canvas, Offset(x, y + yOffset));
  }

  /// Draw key signature (sharps or flats)
  void _drawKeySignature(Canvas canvas, double x, double y, Clef clef) {
    final sharps = scoreData.keySignature.sharps;
    if (sharps == 0) return; // C major/A minor, no accidentals

    final textStyle = TextStyle(
      fontSize: staffLineSpacing * 2.5,
      color: Colors.black,
      fontWeight: FontWeight.bold,
    );

    if (sharps > 0) {
      // Draw sharps: F C G D A E B
      final sharpPositions = clef == Clef.treble
          ? [0.0, 1.5, -0.5, 1.0, 2.5, 0.5, 2.0] // Staff line positions for treble
          : [1.0, 2.5, 0.5, 2.0, 3.5, 1.5, 3.0]; // For bass

      for (int i = 0; i < sharps; i++) {
        final textSpan = TextSpan(text: '♯', style: textStyle);
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        final xPos = x + (i * staffLineSpacing * 1.2);
        final yPos = y + (sharpPositions[i] * staffLineSpacing) + staffLineSpacing;
        textPainter.paint(canvas, Offset(xPos, yPos));
      }
    } else {
      // Draw flats: B E A D G C F
      final flatPositions = clef == Clef.treble
          ? [2.0, 0.5, 2.5, 1.0, 3.0, 1.5, 3.5]
          : [3.0, 1.5, 3.5, 2.0, 4.0, 2.5, 4.5];

      for (int i = 0; i < -sharps; i++) {
        final textSpan = TextSpan(text: '♭', style: textStyle);
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        final xPos = x + (i * staffLineSpacing * 1.2);
        final yPos = y + (flatPositions[i] * staffLineSpacing) + staffLineSpacing;
        textPainter.paint(canvas, Offset(xPos, yPos));
      }
    }
  }

  /// Draw time signature
  void _drawTimeSignature(Canvas canvas, double x, double y) {
    final accidentalWidth = staffLineSpacing * 0.7;

    // check number of sharps or flats
    final sharps = scoreData.keySignature.sharps;
    if (sharps > 0 || sharps < 0) {
      x += (sharps > 0) ? (sharps * accidentalWidth) : (-sharps * accidentalWidth);
    }
    final textStyle = TextStyle(
      fontSize: staffLineSpacing * 3,
      color: Colors.black,
      fontWeight: FontWeight.bold,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    // Draw numerator
    final numeratorPainter = TextPainter(
      text: TextSpan(
        text: '${scoreData.timeSignature.numerator}',
        style: textStyle,
      ),
      textDirection: TextDirection.ltr,
    );
    numeratorPainter.layout();
    numeratorPainter.paint(canvas, Offset(x, y + staffLineSpacing * 0.5));

    // Draw denominator
    final denominatorPainter = TextPainter(
      text: TextSpan(
        text: '${scoreData.timeSignature.denominator}',
        style: textStyle,
      ),
      textDirection: TextDirection.ltr,
    );
    denominatorPainter.layout();
    denominatorPainter.paint(canvas, Offset(x, y + staffLineSpacing * 2.5));
  }

  /// Draw measure bar line
  void _drawMeasureBar(Canvas canvas, double x, double topY, double bottomY) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(x, topY),
      Offset(x, bottomY + staffLineSpacing * 4),
      paint,
    );
  }

  /// Draw playback cursor
  void _drawPlaybackCursor(Canvas canvas, double x, double topY, double bottomY) {
    final paint = Paint()
      ..color = Colors.red.withOpacity(0.6)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(x, topY - 10),
      Offset(x, bottomY + staffLineSpacing * 4 + 10),
      paint,
    );
  }

  /// Calculate width needed for a measure
  double _calculateMeasureWidth(Measure measure) {
    // Base width + space for each element
    final elementCount = measure.trebleElements.length + measure.bassElements.length;
    return (elementCount * pixelsPerBeat * 2).clamp(150.0, 400.0);
  }

  /// Draw notes and rests in a measure
  void _drawMeasureElements(
      Canvas canvas, {
        required Measure measure,
        required double measureX,
        required double trebleStaffY,
        required double bassStaffY,
        required double currentBeat,
      }) {
    // We'll implement note drawing in the next step

  }

  @override
  bool shouldRepaint(StaffPainter oldDelegate) => true;
}

enum Clef { treble, bass }