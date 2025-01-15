import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/piano_state.dart';


class Display extends StatelessWidget {
  const Display({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PianoState>(builder: (context, pianoState, child) {
      return Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF181818),
                Color(0XFF282424),
                Color(0xFF282424)
              ],
              stops: [
                0, 0.25, 1
              ]
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.7),  // Dark shadow
              offset: const Offset(-4, -4),  // Bottom-right shadow
              blurRadius: 10,  // Soften the shadow
              spreadRadius: -4,  // Make the shadow tighter inside
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.2),  // Highlight shadow
              offset: const Offset(-4, -4),  // Top-left shadow for highlighting
              blurRadius: 10,
              spreadRadius: -4,  // Spread towards the inside
            ),
          ],
          borderRadius: BorderRadius.circular(15),
          color: const Color(0xFF282424),

        ),
        margin: const EdgeInsets.symmetric(horizontal: 30),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        width: 400, // Adjust this value
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(pianoState.octave.toString(), style: const TextStyle(fontSize: 30, color: Colors.grey, fontFamily: 'AtomicClockRadio'),),
            Text(pianoState.currentNote, style: const TextStyle(fontSize: 50, color: Colors.grey, fontFamily: 'AtomicClockRadio'),),
            Text('${pianoState.volume.toInt()}', style: const TextStyle(fontSize: 30, color: Colors.grey, fontFamily: 'AtomicClockRadio'),),
          ],
        ),
      );
    });
  }
}
