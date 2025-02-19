// piano_keys.dart
import 'package:flutter/material.dart';
import 'package:empyrealkeys/components/piano_keyboard/white_keys.dart';
import 'package:provider/provider.dart';

import '../../state/midi_provider.dart';
import '../../state/piano_state.dart';
import 'black_keys.dart';
import 'piano_key_listener.dart'; // Import the new widget

class PianoKeys extends StatefulWidget {
  const PianoKeys({super.key});

  @override
  State<PianoKeys> createState() => _PianoKeysState();
}

class _PianoKeysState extends State<PianoKeys> {
  var _displayedNote = '...';

  void onKeyPress(String note) {
    setState(() {
      _displayedNote = note;
    });
    print(_displayedNote);
  }

  @override
  Widget build(BuildContext context) {
    final numberOfKeys = Provider.of<PianoState>(context).numberOfKeys;
    List<int> whiteKeyIndices = [
      0,
      2,
      4,
      5,
      7,
      9,
      11,
      12,
      14,
      16,
      17,
      19,
      21,
      23,
      24
    ];
    List<int> blackKeyIndices = [1, 3, 6, 8, 10, 13, 15, 18, 20, 22, 25];
    List<Widget> blackKeys = [];
    List<double> blackKeyOffsets = [
      0.75,
      1.75,
      3.75,
      4.75,
      5.75,
      7.75,
      8.75,
      10.75,
      11.75,
      12.75,
      14.75
    ];
    double whiteKeyWidth = (MediaQuery.of(context).size.width - 60) /
        numberOfKeys; // 60 is total padding around row of piano keys
    double blackKeyWidth = whiteKeyWidth * 0.5;
    for (int i = 0; i < blackKeyIndices.length; i++) {
      blackKeys.add(Positioned(
        left: whiteKeyWidth * blackKeyOffsets[i],
        child: BlackKey(
          idx: blackKeyIndices[i],
          keyWidth: blackKeyWidth,
        ),
      ));
    }
    return Expanded(
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF000000),
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
              bottomRight: Radius.circular(30),
              bottomLeft: Radius.circular(30)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Consumer<MidiProvider>(builder: (context, midiProvider, child) {
            return midiProvider.isSoundfontLoaded
                ? PianoKeyListener(
              whiteKeyIndices: whiteKeyIndices,
              blackKeyIndices: blackKeyIndices,
              blackKeyOffsets: blackKeyOffsets,
              whiteKeyWidth: whiteKeyWidth,
              blackKeyWidth: blackKeyWidth,
              numberOfKeys: numberOfKeys,
              child: Stack(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(numberOfKeys, (index) {
                      String keyType;

                      // Assign the key type based on the index
                      if (index == 0) {
                        keyType = 'leftKey';
                      } else if (index == numberOfKeys - 1) {
                        keyType = 'rightKey';
                      } else {
                        keyType = 'centralKey';
                      }
                      return Expanded(
                          child: WhiteKey(
                              idx: whiteKeyIndices[index],
                              keyType: keyType));
                    }),
                  ),
                  ...blackKeys
                ],
              ),
            )
                : Stack(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(numberOfKeys, (index) {
                    String keyType;

                    // Assign the key type based on the index
                    if (index == 0) {
                      keyType = 'leftKey';
                    } else if (index == numberOfKeys - 1) {
                      keyType = 'rightKey';
                    } else {
                      keyType = 'centralKey';
                    }
                    return Expanded(
                        child: WhiteKey(
                            idx: whiteKeyIndices[index],
                            keyType: keyType));
                  }),
                ),
                ...blackKeys,
                Container(
                    color: Colors.black.withOpacity(0.7),
                    child: const Center(
                        child: CircularProgressIndicator())),
              ],
            );
          }),
        ),
      ),
    );
  }
}