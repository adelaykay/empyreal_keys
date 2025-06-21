import 'package:connectivity_plus/connectivity_plus.dart';
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
  bool isExpandedPracticeAids = false;
  String?
      selectedInstrumentType; // This stores the currently selected instrument type
  String? selectedInstrumentName;
  final ScrollController _scrollController = ScrollController();
  Future<bool> _hasInternet() async {
    List<ConnectivityResult> status = await Connectivity().checkConnectivity();
    return !status.contains(ConnectivityResult.none);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _playHallelujahChorus(BuildContext ctx) {
    final midi = Provider.of<MidiProvider>(ctx, listen: false);
    final velocity = Provider.of<PianoState>(ctx, listen: false).volume;

    // The correct “Hallelujah” motif:
    final sequence = [72, 67, 69, 67];
    const beatMs = 250; // one “beat” in ms
    final durations = [3 * beatMs, beatMs, beatMs, beatMs];

    int elapsed = 0;
    for (var i = 0; i < sequence.length; i++) {
      final note = sequence[i];
      final dur = durations[i];

      // schedule note-on at elapsed
      Future.delayed(Duration(milliseconds: elapsed), () {
        midi.playNote(midiNote: note, velocity: velocity);
      });

      // schedule note-off at elapsed + dur
      Future.delayed(Duration(milliseconds: elapsed + dur), () {
        midi.stopNote(midiNote: note);
      });

      elapsed += dur; // move to next
    }

    // optional congratulations
    ScaffoldMessenger.of(ctx)
        .showSnackBar(SnackBar(content: Text('🎉 Hallelujah unlocked!')));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final pianoState = Provider.of<PianoState>(context);
    final numberOfKeys = pianoState.numberOfKeys;
    var showNoteNames = pianoState.showNoteNames;
    var isChordMode = pianoState.isChordMode;
    var chordType = pianoState.chordType;

    return Consumer<PianoState>(
      builder: (context, pianoState, child) {
        final instruments = pianoState.instruments;
        return Scrollbar(
          controller: _scrollController,
          trackVisibility: true,
          thumbVisibility: true,
          thickness: 8,
          child: SingleChildScrollView(
            controller: _scrollController,
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
                  margin: EdgeInsets.symmetric(horizontal: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        offset: const Offset(1, 2),
                        blurRadius: 0.2,
                        spreadRadius: 0.3,
                      ),
                    ],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.grey,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text('Select Instrument Group:', style: TextStyle()),
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
                                style:
                                    TextStyle(fontSize: screenHeight * 0.03)),
                          ],
                        ),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedInstrumentType = newValue;
                            pianoState.setInstrumentType(newValue!);
                          });
                          // give the list a frame to rebuild, then scroll
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _scrollController.animateTo(
                              _scrollController.position.maxScrollExtent,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          });
                        },
                        items: instruments.keys
                            .map<DropdownMenuItem<String>>((String type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type,
                                style:
                                    TextStyle(fontSize: screenHeight * 0.03)),
                          );
                        }).toList(),
                      ),
                      if (selectedInstrumentType != null)
                        // Enhanced Instrument Picker with fun, branded offline dialog + Easter egg
                        Builder(
                          builder: (ctx) => InkWell(
                            onTap: () async {
                              if (!await _hasInternet()) {
                                // No internet → fun, branded alert with Easter egg trigger
                                int tapCount = 0;
                                showDialog(
                                  context: ctx,
                                  builder: (_) => StatefulBuilder(
                                    builder: (context, setState) {
                                      return AlertDialog(
                                        backgroundColor: Colors.teal.shade700,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        title: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              tapCount++;
                                            });
                                            if (tapCount >= 5) {
                                              // Easter egg: show surprise
                                              _playHallelujahChorus(context);
                                              ScaffoldMessenger.of(ctx)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      '🎉 You found the secret chord! 🎹'),
                                                  backgroundColor:
                                                      Colors.orangeAccent,
                                                  duration:
                                                      Duration(seconds: 2),
                                                ),
                                              );
                                            }
                                          },
                                          child: Row(
                                            children: [
                                              Icon(Icons.music_off,
                                                  color: Colors.orangeAccent,
                                                  size: 32),
                                              SizedBox(width: 8),
                                              Text(
                                                tapCount >= 5
                                                    ? 'Rock on! 🤘'
                                                    : 'Oops!',
                                                style: TextStyle(
                                                  color: Colors.orangeAccent,
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              "Looks like you're offline.\nConnect to Wi‑Fi or data to download your new sound!",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            SizedBox(height: 12),
                                            Icon(Icons.headphones,
                                                color: Colors.orangeAccent,
                                                size: 48),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            child: Text(
                                              tapCount >= 5
                                                  ? 'Keep Jammin’'
                                                  : 'Got it!',
                                              style: TextStyle(
                                                  color: Colors.orangeAccent),
                                            ),
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(),
                                          )
                                        ],
                                      );
                                    },
                                  ),
                                );
                                return;
                              }

                              // Otherwise—open instrument picker
                              final selected = await showMenu<String>(
                                context: ctx,
                                position: RelativeRect.fromLTRB(
                                    screenWidth / 2,
                                    screenHeight / 2,
                                    screenWidth / 2,
                                    screenHeight / 2),
                                items: instruments[selectedInstrumentType!]!
                                    .map((instr) {
                                  final name = instr.keys.first;
                                  final file = instr.values.first;
                                  return PopupMenuItem<String>(
                                    value: file,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(name,
                                            style: TextStyle(
                                                fontSize: screenHeight * 0.03)),
                                        file != 'Default.SF2'
                                            ? Icon(Icons.download_rounded,
                                                color: Colors.orangeAccent)
                                            : SizedBox(),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              );

                              if (selected != null) {
                                final name =
                                    instruments[selectedInstrumentType!]!
                                        .firstWhere(
                                            (i) => i.values.first == selected)
                                        .keys
                                        .first;

                                Provider.of<MidiProvider>(context,
                                        listen: false)
                                    .isSoundfontLoaded = false;
                                setState(() {
                                  selectedInstrumentName = name;
                                });

                                pianoState.setInstrument(name);
                                pianoState.setInstrument(selected);
                                Provider.of<MidiProvider>(ctx, listen: false)
                                    .loadMidi(selected);
                              }
                            },
                            child: ListTile(
                              title: Text(
                                selectedInstrumentName ?? 'Select instrument…',
                                style: TextStyle(
                                    fontSize: screenHeight * 0.03,
                                    color: Colors.teal),
                              ),
                              trailing: Icon(Icons.arrow_drop_down,
                                  color: Colors.orangeAccent),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  color: Theme.of(context).colorScheme.surface,
                  margin: EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
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
                            padding:
                                const EdgeInsets.symmetric(horizontal: 30.0),
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
                            padding:
                                const EdgeInsets.symmetric(horizontal: 30.0),
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
                          isChordMode
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 30.0),
                                  child: Divider(
                                    color: Colors.grey,
                                    height: 1,
                                  ),
                                )
                              : SizedBox(
                                  height: 0,
                                ),
                          isChordMode
                              ? _buildDropdownTile(
                                  'Chords Type',
                                  'Select the type of chords to play',
                                  chordType,
                                  pianoState.chordFormulas.keys.toList(),
                                  (String? newValue) {
                                    pianoState.setChordType(newValue!);
                                  },
                                )
                              : SizedBox(
                                  height: 0,
                                ),
                        ],
                        subtitle: 'Enable practice aids for learning',
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.refresh),
                    label: Text('Reset to Defaults'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor:
                          Theme.of(context).colorScheme.onSecondary,
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: pianoState.resetToDefault,
                  ),
                ),
              ],
            ),
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.symmetric(horizontal: 0, vertical: 10),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Colors.grey,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              offset: const Offset(1, 2),
              blurRadius: 0.1,
              spreadRadius: 0.1),
        ],
      ),
      child: ListTile(
        title: Text("$title: ${value.toStringAsFixed(0)}"),
        subtitle: SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Theme.of(context).colorScheme.primary,
            inactiveTrackColor:
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5),
            trackHeight: MediaQuery.of(context).size.height * 0.015,
            thumbColor: Theme.of(context).colorScheme.primary,
            overlayColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
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
      ),
    );
  }

  Widget _buildSwitchTile(
      String title, String info, bool value, Function(bool) onChanged) {
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
