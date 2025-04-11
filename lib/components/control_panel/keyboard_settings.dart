import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/ph.dart';
import 'package:interactive_slider/interactive_slider.dart';
import 'package:provider/provider.dart';
// import '../../services/soundfont.dart';
import '../../state/midi_provider.dart';
import '../../state/piano_state.dart';

class KeyboardSettings extends StatefulWidget {
  const KeyboardSettings({super.key});

  @override
  State<KeyboardSettings> createState() => _KeyboardSettingsState();
}

class _KeyboardSettingsState extends State<KeyboardSettings> {
  String?
      selectedInstrumentType; // This stores the currently selected instrument type
  String? selectedInstrumentName;

  @override
  Widget build(BuildContext context) {
    return Consumer<PianoState>(
      builder: (context, pianoState, child) {
        final instruments = pianoState.instruments;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: const Color(0xffcccccc),
              width: MediaQuery.of(context).size.width /2,
              height: 1,
            ),
            const SizedBox(height: 10,),
            // Number of Keys Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text('Number of Keys: ', style: TextStyle(fontSize: MediaQuery.sizeOf(context).height * 0.03)),
                Expanded(
                  child: InteractiveSlider(
                    focusedHeight: MediaQuery.of(context).size.height * 0.04,
                    unfocusedHeight: MediaQuery.of(context).size.height * 0.02,
                    initialProgress: pianoState.numberOfKeys.toDouble(),
                    foregroundColor: const Color(0xFF4A90E2),
                    min: 7,
                    max: 15,
                    numberOfSegments: 8,
                    segmentDividerWidth: 0,
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.secondary,
                        Theme.of(context).colorScheme.primary
                      ],
                      stops: [
                        0, 100
                      ]
                    ),
                    segmentDividerColor: Colors.transparent,
                    endIcon: Text('${pianoState.numberOfKeys}', style: TextStyle(fontSize: MediaQuery.sizeOf(context).height * 0.03, color: Theme.of(context).colorScheme.onSurface)),
                    onChanged: (double value) {
                      setState(() {
                        pianoState.setNumberOfKeys(
                            value.toInt()); // Update number of keys
                      });
                    },
                  ),
                ),
              ],
            ),
            // Instrument Selector
            const SizedBox(height: 10),
            Text('Select Instrument Type:', style: TextStyle(fontSize: MediaQuery.sizeOf(context).height * 0.03)),
            DropdownButton<String>(
              value: selectedInstrumentType,
              hint: Row(
                children: [
                  Iconify(Ph.piano_keys, color: Theme.of(context).colorScheme.primary,),
                  const SizedBox(width: 10,),
                  Text(pianoState.selectedInstrumentType, style: TextStyle(fontSize: MediaQuery.sizeOf(context).height * 0.03)),
                ],
              ),
              onChanged: (String? newValue) {
                setState(() {
                  selectedInstrumentType = newValue;
                });
              },
              items:
                  instruments.keys.map<DropdownMenuItem<String>>((String type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type, style: TextStyle(fontSize: MediaQuery.sizeOf(context).height * 0.03)),
                );
              }).toList(),
            ),
            if (selectedInstrumentType != null)
              PopupMenuButton<String>(
                onSelected: (String instrumentFile) {
                  setState(() {
                    Provider.of<MidiProvider>(context, listen: false)
                        .isSoundfontLoaded = false;
                    pianoState.setInstrument(instrumentFile);
                    Provider.of<MidiProvider>(context, listen: false)
                        .loadMidi(instrumentFile);
                  });
                },
                child: ListTile(
                  title: Text(
                    selectedInstrumentName ?? 'Select instrument:', style: TextStyle(fontSize: MediaQuery.sizeOf(context).height * 0.03),
                  ),
                  trailing: const Icon(Icons.arrow_drop_down),
                ),
                itemBuilder: (BuildContext context) {
                  // Dynamically generate menu items based on the selected instrument type
                  return instruments[selectedInstrumentType!]!
                      .map((Map<String, String> instrument) {
                    String instrumentName = instrument.keys.first;
                    String soundfontFile = instrument.values.first;
                    // final soundfontService = SoundfontService();
                    return PopupMenuItem<String>(
                      onTap: () {
                        if (kDebugMode) {
                          print('$instrumentName: $soundfontFile');
                        }
                        setState(() {
                          selectedInstrumentName = instrumentName;
                        });
                        pianoState.setInstrument(soundfontFile);
                      },
                      value: soundfontFile,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(instrumentName, style: TextStyle(fontSize: MediaQuery.sizeOf(context).height * 0.03)),
                          soundfontFile != 'Default.SF2' ? const Iconify(Ph.download) : const SizedBox(),
                        ],
                      ),
                    );
                  }).toList();
                },
              ),
          ],
        );
      },
    );
  }
}
