import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/midi_provider.dart';
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
    final notes = Provider.of<PianoState>(context).notes;
    final midiProvider = Provider.of<MidiProvider>(context, listen: false);
    final octave = Provider.of<PianoState>(context).octave;
    final volume = Provider.of<PianoState>(context).volume;
    int midiNote = 12 + (octave * 12) + idx;
    return GestureDetector(
      onTapDown: (details) async {
        try {
          midiProvider.playNote(midiNote: midiNote, velocity: volume);
        } catch (e) {
          print('An error occured: $e');
        }
        Provider.of<PianoState>(context, listen: false)
            .setCurrentNote(notes[idx]);
      },
      onTapUp: (details) async {
        // await player.stop();
        midiProvider.stopNote(midiNote: midiNote);
        Provider.of<PianoState>(context, listen: false).setCurrentNote('..');
      },
      onTapCancel: () async {
        // await player.stop();
        midiProvider.stopNote(midiNote: midiNote);
        Provider.of<PianoState>(context, listen: false).setCurrentNote('..');
      },
      child: Container(
        decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10)),
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF000000),
                  Color(0xFF222222),
                ])),
        width: keyWidth,
        height: MediaQuery.of(context).size.height * 0.35,
      ),
    );
  }
}
