import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/metronome_service.dart';
import '../../state/piano_state.dart';

class MetronomePanel extends StatefulWidget {
  final double screenWidth;
  final double screenHeight;

  const MetronomePanel({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  State<MetronomePanel> createState() => _MetronomePanelState();
}

class _MetronomePanelState extends State<MetronomePanel> {
  late final MetronomeService metronomeService;
  bool showAdvanced = false;
  Timer? _holdTimer;

  @override
  void initState() {
    super.initState();
    final pianoState = Provider.of<PianoState>(context, listen: false);
    metronomeService = MetronomeService(pianoState);
  }

  @override
  void dispose() {
    metronomeService.stop(immediate: true);
    super.dispose();
  }

  void stopHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final pianoState = Provider.of<PianoState>(context);

    void changeBpm(int delta) {
      final newBpm = (pianoState.bpm + delta).clamp(20, 300);
      pianoState.setBpm(newBpm);
      if (metronomeService.isPlayingMetronome) {
        metronomeService.start(); // restart with new BPM
      }
    }

    return ChangeNotifierProvider.value(
      value: metronomeService,
      child: Consumer<MetronomeService>(
        builder: (context, metro, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // AnimatedCrossFade(
              //   firstChild: Row(
              //     children: [
              //       Icon(Icons.access_time,
              //           color: Theme.of(context).primaryColor,
              //           size: widget.screenHeight * 0.05),
              //       const SizedBox(width: 8),
              //       Text(
              //         "Metronome",
              //         style: TextStyle(
              //           fontSize: widget.screenHeight * 0.05,
              //           fontWeight: FontWeight.bold,
              //           color: Theme.of(context).primaryColor,
              //         ),
              //       ),
              //     ],
              //   ),
              //   secondChild: const SizedBox.shrink(),
              //   crossFadeState: showAdvanced
              //       ? CrossFadeState.showSecond
              //       : CrossFadeState.showFirst,
              //   duration: const Duration(milliseconds: 400),
              // ),

              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Header Row
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedCrossFade(
                          firstChild: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Icon(Icons.access_time_rounded,
                                color: Theme.of(context).primaryColor,
                                size: widget.screenHeight * 0.08),
                          ),
                          secondChild: SizedBox(
                            width: 8,
                          ),
                          crossFadeState: showAdvanced
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 400),
                        ),

                        // Play / Stop Button
                        IconButton(
                          iconSize: widget.screenHeight * 0.10,
                          icon: Icon(
                            metro.isPlayingMetronome
                                ? Icons.stop_rounded
                                : Icons.play_arrow_rounded,
                            color: metro.isPlayingMetronome
                                ? Colors.red
                                : Color(0xFFBCBCBC),
                          ),
                          onPressed: metro.toggleMetronome,
                        ),

                        // BPM Controls
                        Row(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12.0),
                              child: GestureDetector(
                                onTapDown: (_) {
                                  changeBpm(-1);
                                  _holdTimer = Timer.periodic(
                                    const Duration(milliseconds: 120),
                                    (_) => changeBpm(-1),
                                  );
                                },
                                onTapUp: (_) => stopHold(),
                                onTapCancel: stopHold,
                                child: Icon(Icons.remove_rounded,
                                    color: Color(0xFFBCBCBC),
                                    size: widget.screenWidth * 0.04),
                              ),
                            ),
                            InkWell(
                              onTap: () async {
                                final controller = TextEditingController(
                                    text: pianoState.bpm.toString());
                                final newVal = await showDialog<int>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("Set BPM"),
                                    content: TextField(
                                      controller: controller,
                                      keyboardType: TextInputType.number,
                                      style: TextStyle(
                                        fontSize: widget.screenHeight * 0.05,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                      decoration: const InputDecoration(
                                          hintText: "BPM"),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text("Cancel"),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          final parsed =
                                              int.tryParse(controller.text);
                                          Navigator.pop(context, parsed);
                                        },
                                        child: const Text("OK"),
                                      ),
                                    ],
                                  ),
                                );
                                if (newVal != null) {
                                  pianoState.setBpm(newVal.clamp(20, 300));
                                  if (metro.isPlayingMetronome) metro.start();
                                }
                              },
                              child: Text(pianoState.bpm.toString(),
                                  style: TextStyle(
                                    fontSize: widget.screenHeight * 0.07,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFBCBCBC),
                                  )),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12.0),
                              child: GestureDetector(
                                onTapDown: (_) {
                                  changeBpm(1);
                                  _holdTimer = Timer.periodic(
                                    const Duration(milliseconds: 120),
                                    (_) => changeBpm(1),
                                  );
                                },
                                onTapUp: (_) => stopHold(),
                                onTapCancel: stopHold,
                                child: Icon(Icons.add_rounded,
                                    color: Color(0xFFBCBCBC),
                                    size: widget.screenWidth * 0.04),
                              ),
                            ),
                          ],
                        ),

                        // Advanced Toggle
                        Row(
                          children: [
                            AnimatedCrossFade(
                              firstChild: const SizedBox.shrink(),
                              secondChild: Padding(
                                padding: EdgeInsets.only(
                                    top: widget.screenHeight * 0.01),
                                child: Wrap(
                                  spacing: 20,
                                  children: [
                                    // Time Signature
                                    DropdownButton<String>(
                                      dropdownColor: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(
                                              widget.screenHeight * 0.03)),
                                      value: pianoState.timeSig,
                                      items: ["2/4", "3/4", "4/4", "6/8"]
                                          .map((sig) {
                                        return DropdownMenuItem(
                                          value: sig,
                                          child: Text(
                                            sig,
                                            style: TextStyle(
                                              color: const Color(0xFFBCBCBC),
                                              fontSize:
                                                  widget.screenWidth * 0.012,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (newVal) {
                                        if (newVal != null) {
                                          pianoState.setTimeSignature(newVal);
                                          if (metro.isPlayingMetronome) {
                                            metro.start();
                                          }
                                        }
                                      },
                                    ),

                                    // Accent First
                                    Row(
                                      children: [
                                        Text(
                                          "Accent 1",
                                          style: TextStyle(
                                            color: const Color(0xFFBCBCBC),
                                            fontSize:
                                                widget.screenWidth * 0.012,
                                          ),
                                        ),
                                        Transform.scale(
                                          scale: 0.8,
                                          child: Switch(
                                            inactiveThumbColor:
                                                Color(0xFFBCBCBC),
                                            value: pianoState.accentFirst,
                                            onChanged: (val) {
                                              pianoState.setAccentFirst(val);
                                            },
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Sound
                                    DropdownButton<String>(
                                      dropdownColor: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(
                                              widget.screenHeight * 0.03)),
                                      value: pianoState.metronomeSound,
                                      items: ["Click", "Woodblock"].map((s) {
                                        return DropdownMenuItem(
                                          value: s,
                                          child: Text(
                                            s,
                                            style: TextStyle(
                                              color: const Color(0xFFBCBCBC),
                                              fontSize:
                                                  widget.screenWidth * 0.012,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (newVal) {
                                        if (newVal != null) {
                                          pianoState.setMetronomeSound(newVal);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              crossFadeState: showAdvanced
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                              duration: const Duration(milliseconds: 300),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() => showAdvanced = !showAdvanced);
                              },
                              icon: Icon(
                                showAdvanced
                                    ? Icons.keyboard_arrow_left_rounded
                                    : Icons.more_horiz,
                                color: Color(0xFFBCBCBC),
                                size: widget.screenWidth * 0.04,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
