// components/notation/staff_notation_view.dart

import 'package:flutter/material.dart';
import '../../models/recording.dart';
import '../../models/score_data.dart';
import 'staff_painter.dart';

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

  @override
  Widget build(BuildContext context) {
    // Build score data
    final scoreData = StaffNotationData.fromRecording(recording);

    // Calculate total width needed
    final pixelsPerBeat = 50.0;
    final totalBeats = scoreData.measures.isEmpty
        ? 0
        : scoreData.measures.length * scoreData.timeSignature.beatsPerMeasure;
    final totalWidth = 80 + (totalBeats * pixelsPerBeat) + 100; // margins

    // Convert current position (seconds) to beats
    final currentBeat = (currentPosition / 60.0) * scoreData.beatsPerMinute;
    final scrollOffset = currentBeat * pixelsPerBeat;

    // Fixed cursor position (like piano roll - 50px from left)
    final cursorX = 50.0;

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(), // Disable manual scrolling
          child: Transform.translate(
            offset: Offset(-scrollOffset + cursorX, 0), // Auto-scroll to keep cursor fixed
            child: Container(
              width: totalWidth,
              height: screenHeight * 0.35,
              child: CustomPaint(
                painter: StaffPainter(
                  scoreData: scoreData,
                  currentPosition: currentPosition,
                  pixelsPerBeat: pixelsPerBeat,
                  staffLineSpacing: 9.0,
                  cursorX: cursorX, // Pass fixed cursor position
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}