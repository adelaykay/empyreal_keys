// components/debug/quantization_test_widget.dart
// Debug widget to test quantization before we build the renderer

import 'package:flutter/material.dart';
import '../../models/recording.dart';
import '../../models/score_data.dart';
import '../../services/quantizer.dart';

class QuantizationTestWidget extends StatelessWidget {
  final Recording recording;

  const QuantizationTestWidget({
    super.key,
    required this.recording,
  });

  @override
  Widget build(BuildContext context) {
    // Build staff notation data
    final scoreData = StaffNotationData.fromRecording(recording);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Metadata
            Text(
              'Piece: ${recording.title}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 8),
            Text(
              'Key: ${scoreData.keySignature.name}',
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
            Text(
              'Time: ${scoreData.timeSignature}',
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
            Text(
              'Tempo: ${scoreData.beatsPerMinute.toStringAsFixed(0)} BPM',
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
            const SizedBox(height: 16),
            const Divider(),

            // Measures
            ...scoreData.measures.map((measure) => _buildMeasureDebug(measure)),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasureDebug(Measure measure) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Measure ${measure.number + 1}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),

          // Treble clef
          if (measure.trebleElements.isNotEmpty) ...[
            const Text(
              'Treble Clef (Right Hand):',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            ...measure.trebleElements.map((e) => _buildElementDebug(e)),
            const SizedBox(height: 8),
          ],

          // Bass clef
          if (measure.bassElements.isNotEmpty) ...[
            const Text(
              'Bass Clef (Left Hand):',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            ...measure.bassElements.map((e) => _buildElementDebug(e)),
          ],
        ],
      ),
    );
  }

  Widget _buildElementDebug(ScoreElement element) {
    if (element is ScoreNote) {
      final pitchNames = element.pitches.map((p) {
        final accidental = p.showAccidental ? p.spelling.accidental.name : '';
        return '${p.spelling.noteName.name}$accidental${p.spelling.octave}';
      }).join(', ');

      return Padding(
        padding: const EdgeInsets.only(left: 16, top: 4),
        child: Text(
          '${element.isChord ? "Chord" : "Note"}: $pitchNames '
              '(${element.duration.name}, beat ${(element.beatPosition + 1).toStringAsFixed(2)})',
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
      );
    } else if (element is ScoreRest) {
      return Padding(
        padding: const EdgeInsets.only(left: 16, top: 4),
        child: Text(
          'Rest: ${element.duration.name} '
              '(beat ${(element.beatPosition + 1).toStringAsFixed(2)})',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}