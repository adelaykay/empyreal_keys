import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:iconify_flutter/icons/ph.dart';
import 'package:provider/provider.dart';
import '../../state/midi_provider.dart';
import '../../state/piano_state.dart';

class KeyboardSettings extends StatefulWidget {
  const KeyboardSettings({super.key});

  @override
  State<KeyboardSettings> createState() => _KeyboardSettingsState();
}

class _KeyboardSettingsState extends State<KeyboardSettings> {
  String currentKey = 'C';
  bool isExpandedPracticeAids = false;
  String?
  selectedInstrumentType; // This stores the currently selected instrument type
  String? selectedInstrumentName;


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final pianoState = Provider.of<PianoState>(context);
    final numberOfKeys = pianoState.numberOfKeys;
    var showNoteNames = pianoState.showNoteNames;
    var isChordMode = pianoState.isChordMode;


    return Consumer<PianoState>(
      builder: (context, pianoState, child) {
        final instruments = pianoState.instruments;
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Divider
              Container(
                margin: EdgeInsets.symmetric(vertical: 10),
                width: screenWidth * 0.4,
                height: 1,
                color: Colors.grey,
              ),
              const SizedBox(
                height: 10,
              ),
              // Number of Keys Selector
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildSliderTile(
                    'Number of Keys',
                    numberOfKeys.toDouble(),
                    7,
                    15,
                    (value) {
                      setState(() {
                        pianoState.setNumberOfWhiteKeys(value.toInt());
                      });
                    },
                  ),
                ],
              ),
              // Instrument Selector
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                child: Column(
                  children: [
                    Text('Select Instrument Type:',
                        style: TextStyle(
                            )),
                    DropdownButton<String>(
                      value: selectedInstrumentType,
                      hint: Row(
                        children: [
                          Iconify(
                            Ph.piano_keys,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Text(pianoState.selectedInstrumentType,
                              style: TextStyle(
                                  fontSize:
                                  screenHeight * 0.03)),
                        ],
                      ),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedInstrumentType = newValue;
                          pianoState.setInstrumentType(newValue!);
                        });
                      },
                      items: instruments.keys
                          .map<DropdownMenuItem<String>>((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type,
                              style: TextStyle(
                                  fontSize:
                                  screenHeight * 0.03)),
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
                            style: TextStyle(
                                fontSize: screenHeight * 0.03),
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
                                  pianoState.setInstrument(instrumentName);
                                });
                                pianoState.setInstrument(soundfontFile);
                              },
                              value: soundfontFile,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(instrumentName,
                                      style: TextStyle(
                                          fontSize:
                                          screenHeight *
                                              0.03)),
                                  soundfontFile != 'Default.SF2'
                                      ? const Iconify(Ph.download)
                                      : const SizedBox(),
                                ],
                              ),
                            );
                          }).toList();
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildExpandableTile(
                    title: 'Practice Aids',
                    icon: Icons.music_note,
                    isExpanded: isExpandedPracticeAids,
                    onExpand: () {
                      setState(() {
                        isExpandedPracticeAids = !isExpandedPracticeAids;
                      });
                    },
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30.0),
                        child: Divider(
                          color: Colors.grey,
                          height: 1,
                        ),
                      ),
                      _buildSwitchTile(
                        'Show Note Labels',
                        'Display note names on the keyboard',
                        showNoteNames,
                        (value) {
                          pianoState.setShowNoteNames(value);
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30.0),
                        child: Divider(
                          color: Colors.grey,
                          height: 1,
                        ),
                      ),
                      _buildSwitchTile(
                        'Chord Mode',
                        'Play chords instead of single notes',
                        isChordMode,
                            (value) {
                          pianoState.setIsChordMode(value);
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30.0),
                        child: Divider(
                          color: Colors.grey,
                          height: 1,
                        ),
                      ),
                      _buildDropdownTile(
                        'Key',
                        'Select the first note of the keyboard',
                        currentKey,
                        ['C', 'D', 'E', 'F', 'G', 'A', 'B'],
                        (String? newValue) {
                          setState(() {
                            currentKey = newValue!;
                          });
                        },
                      ),
                    ],
                    subtitle: 'Enable practice aids for learning',
                  )
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.refresh),
                  label: Text('Reset to Defaults'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Theme.of(context).colorScheme.onSecondary,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: pianoState.resetToDefault,
                ),
              ),

            ],
          ),
        );
      },
    );
  }

  Widget _buildExpandableTile({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onExpand,
    required List<Widget> children,
    required String subtitle,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: ExpansionTile(
        collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.grey)),
        collapsedBackgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: TextStyle()),
        subtitle: Text(subtitle),
        initiallyExpanded: isExpanded,
        onExpansionChanged: (expanded) => onExpand(),
        children: children,
      ),
    );
  }

  Widget _buildSliderTile(
      String title,
      double value,
      double min,
      double max,
      Function(double) onChanged,
      ) {
    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey),
      ),
      tileColor: Colors.transparent,
      title: Text("$title: ${value.toStringAsFixed(0)}"),
      subtitle: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor: Theme.of(context).colorScheme.primary,
          inactiveTrackColor: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
          trackHeight: MediaQuery.of(context).size.height * 0.015,
          thumbColor: Theme.of(context).colorScheme.primary,
          overlayColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          valueIndicatorColor: Theme.of(context).colorScheme.secondary,
          valueIndicatorTextStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSecondary,
          ),
        ),
        child: Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          label: value.toStringAsFixed(0),
          onChanged: onChanged,
        ),
      ),
    );
  }


  Widget _buildSwitchTile(String title, String info, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(left: 28.0),
      child: SwitchListTile(
        tileColor: Colors.transparent,
        title: Row(
          children: [
            Text(title),
            // Info button
            IconButton(
              icon: Iconify(
                Mdi.information_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () {
                // Show info dialog or tooltip
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      content: Text(info),
                      actions: [
                        TextButton(
                          child: Text('OK'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDropdownTile(String title, String info, String selectedValue,
      List<String> options, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(left: 28.0),
      child: ListTile(
        tileColor: Colors.transparent,
        title: Row(
          children: [
            Text(title),
            // Info button
            IconButton(
              icon: Iconify(
                Mdi.information_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () {
                // Show info dialog or tooltip
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      content: Text(info),
                      actions: [
                        TextButton(
                          child: Text('OK'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
        trailing: DropdownButton<String>(
          value: selectedValue,
          items: options
              .map((option) =>
                  DropdownMenuItem(value: option, child: Text(option)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}


