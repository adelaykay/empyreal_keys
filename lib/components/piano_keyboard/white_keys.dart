import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/midi_provider.dart';
import '../../state/piano_state.dart';

class WhiteKey extends StatelessWidget {
  final String keyType;
  final int idx;
  const WhiteKey({
    super.key,
    required this.keyType,
    required this.idx,
  });

  @override
  Widget build(BuildContext context) {
    final notes = Provider.of<PianoState>(context).notes;
    final midiProvider = Provider.of<MidiProvider>(context, listen: false);
    final octave = Provider.of<PianoState>(context).octave;
    final volume = Provider.of<PianoState>(context).volume;
    int midiNote = 12 + (octave * 12) + idx;
    return Consumer<PianoState>(builder: (context, pianoState, child) {
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
          // player.stop();
          midiProvider.stopNote(midiNote: midiNote);
          Provider.of<PianoState>(context, listen: false).setCurrentNote('..');
        },
        onTapCancel: () async {
          // player.stop();
          midiProvider.stopNote(midiNote: midiNote);
          Provider.of<PianoState>(context, listen: false).setCurrentNote('..');
        },
        child: Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: keyType == 'rightKey'
                  ? const BorderRadius.only(
                      topRight: Radius.circular(10),
                      bottomRight: Radius.circular(20),
                      bottomLeft: Radius.circular(5))
                  : (keyType == 'leftKey'
                      ? const BorderRadius.only(
                          topLeft: Radius.circular(10),
                          bottomRight: Radius.circular(5),
                          bottomLeft: Radius.circular(20))
                      : const BorderRadius.only(
                          topLeft: Radius.circular(5),
                          topRight: Radius.circular(5),
                          bottomRight: Radius.circular(5),
                          bottomLeft: Radius.circular(5),
                        ))),
          margin: const EdgeInsets.all(2),
        ),
      );
    });
  }
}
