import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/ph.dart';
import 'package:interactive_slider/interactive_slider.dart';
import 'package:provider/provider.dart';
import '../../services/soundfont.dart';
import '../../state/midi_provider.dart';
import '../../state/piano_state.dart';

class KeyboardSettings extends StatefulWidget {
  @override
  _KeyboardSettingsState createState() => _KeyboardSettingsState();
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
              children: [
                const Text('Number of Keys: '),
                Expanded(
                  child: InteractiveSlider(
                    initialProgress: pianoState.numberOfKeys.toDouble(),
                    foregroundColor: const Color(0xFF4A90E2),
                    min: 7,
                    max: 15,
                    numberOfSegments: 8,
                    segmentDividerWidth: 0,
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF4A90E2),
                        Color(0xFFE76F6B)
                      ],
                      stops: [
                        0, 100
                      ]
                    ),
                    segmentDividerColor: Colors.transparent,
                    endIcon: Text('${pianoState.numberOfKeys}'),
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
            const Text('Select Instrument:'),
            DropdownButton<String>(
              value: selectedInstrumentType,
              hint: Row(
                children: [
                  const Iconify(Ph.piano_keys),
                  const SizedBox(width: 10,),
                  Text(pianoState.selectedInstrumentType),
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
                  child: Text(type),
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
                    selectedInstrumentName ?? 'Select instrument:',
                    style: const TextStyle(fontSize: 16),
                  ),
                  trailing: const Icon(Icons.arrow_drop_down),
                ),
                itemBuilder: (BuildContext context) {
                  // Dynamically generate menu items based on the selected instrument type
                  return instruments[selectedInstrumentType!]!
                      .map((Map<String, String> instrument) {
                    String instrumentName = instrument.keys.first;
                    String soundfontFile = instrument.values.first;
                    final soundfontService = SoundfontService();
                    return PopupMenuItem<String>(
                      onTap: () {
                        print('$instrumentName: $soundfontFile');
                        setState(() {
                          selectedInstrumentName = instrumentName;
                        });
                        pianoState.setInstrument(soundfontFile);
                      },
                      value: soundfontFile,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(instrumentName),
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
