import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/piano_state.dart';

class BlackKey extends StatelessWidget {
  final double keyWidth;
  final int idx;
  const BlackKey({
    super.key,
    required this.keyWidth,
    required this.idx,
  });

  @override
  Widget build(BuildContext context) {
    final pianoState = Provider.of<PianoState>(context);
    final octave = pianoState.octave;
    final midiNote = 12 + (octave * 12) + idx;
    final isHighlighted = pianoState.activePlayAlongNotes.contains(midiNote);

    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isHighlighted
              ? [
            Color(0xFF003F42),
            Color(0xFF015C61),
                ]
              : const [
                  Color(0xFF000000),
                  Color(0xFF222222),
                ],
        ),
        border: isHighlighted
            ? Border.all(
                color: Colors.white,
                width: 2,
              )
            : null,
      ),
      width: keyWidth,
      height: pianoState.showingScore
          ? pianoState.panelHeight! * 0.35
          : MediaQuery.of(context).size.height * 0.33,
    );
  }
}
