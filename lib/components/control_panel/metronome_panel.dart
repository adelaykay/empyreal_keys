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
      if (metronomeService.isPlaying) {
        metronomeService.start(); // restart with new BPM
      }
    }

    return ChangeNotifierProvider.value(
      value: metronomeService,
      child: Consumer<MetronomeService>(
        builder: (context, metro, _) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  AnimatedCrossFade(
                    firstChild: Row(
                      children: [
                        Icon(Icons.access_time,
                            color: Theme.of(context).primaryColor,
                            size: widget.screenHeight * 0.05),
                        const SizedBox(width: 8),
                        Text(
                          "Metronome",
                          style: TextStyle(
                            fontSize: widget.screenHeight * 0.05,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                    secondChild: const SizedBox.shrink(),
                    crossFadeState: showAdvanced
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 400),
                  ),

                  // Play / Stop Button
                  IconButton(
                      iconSize: widget.screenHeight * 0.2,
                      icon: Icon(
                        metro.isPlaying
                            ? Icons.stop_circle
                            : Icons.play_circle_fill,
                        color: metro.isPlaying
                            ? Colors.red
                            : Theme.of(context).primaryColor,
                      ),
                      onPressed: metro.toggleMetronome,
                    ),

                  // BPM Controls
                  Row(
                    children: [
                      GestureDetector(
                        onTapDown: (_) {
                          changeBpm(-1);
                          _holdTimer = Timer.periodic(
                            const Duration(milliseconds: 120),
                                (_) => changeBpm(-1),
                          );
                        },
                        onTapUp: (_) => stopHold(),
                        onTapCancel: stopHold,
                        child: Icon(Icons.remove,
                            color: Colors.white,
                            size: widget.screenWidth * 0.07),
                      ),
                      InkWell(
                        onTap: () async {
                          final controller =
                          TextEditingController(text: pianoState.bpm.toString());
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
                                decoration: const InputDecoration(hintText: "BPM"),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    final parsed = int.tryParse(controller.text);
                                    Navigator.pop(context, parsed);
                                  },
                                  child: const Text("OK"),
                                ),
                              ],
                            ),
                          );
                          if (newVal != null) {
                            pianoState.setBpm(newVal.clamp(20, 300));
                            if (metro.isPlaying) metro.start();
                          }
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                                pianoState.bpm.toString(),
                                style: TextStyle(
                                  fontSize: widget.screenHeight * 0.07,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                )
                            ),
                            Text(
                              "BPM",
                              style: TextStyle(
                                fontSize: widget.screenHeight * 0.03,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTapDown: (_) {
                          changeBpm(1);
                          _holdTimer = Timer.periodic(
                            const Duration(milliseconds: 120),
                                (_) => changeBpm(1),
                          );
                        },
                        onTapUp: (_) => stopHold(),
                        onTapCancel: stopHold,
                        child: Icon(Icons.add,
                            color: Colors.white,
                            size: widget.screenWidth * 0.07),
                      ),
                    ],
                  ),

                  // Advanced Toggle
                  Column(
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() => showAdvanced = !showAdvanced);
                        },
                        child: Text(
                          showAdvanced ? "Hide Advanced" : "Show Advanced",
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: widget.screenHeight * 0.03,
                          ),
                        ),
                      ),
                      AnimatedCrossFade(
                        firstChild: const SizedBox.shrink(),
                        secondChild: Padding(
                          padding: EdgeInsets.only(top: widget.screenHeight * 0.01),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Time Signature
                              DropdownButton<String>(
                                dropdownColor:
                                Theme.of(context).colorScheme.onSurface,
                                borderRadius: BorderRadius.all(Radius.circular(widget.screenHeight * 0.03)),
                                value: pianoState.timeSig,
                                items: ["2/4", "3/4", "4/4", "6/8"].map((sig) {
                                  return DropdownMenuItem(
                                    value: sig,
                                    child: Text(sig, style: const TextStyle(color: Colors.white)),
                                  );
                                }).toList(),
                                onChanged: (newVal) {
                                  if (newVal != null) {
                                    pianoState.setTimeSignature(newVal);
                                    if (metro.isPlaying) metro.start();
                                  }
                                },
                              ),
                              SizedBox(width: widget.screenWidth * 0.03),

                              // Accent First
                              Row(
                                children: [
                                  const Text("Accent 1", style: TextStyle(color: Colors.white)),
                                  Switch(
                                    value: pianoState.accentFirst,
                                    onChanged: (val) {
                                      pianoState.setAccentFirst(val);
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(width: widget.screenWidth * 0.03),

                              // Sound
                              DropdownButton<String>(
                                dropdownColor:
                                Theme.of(context).colorScheme.onSurface,
                                borderRadius: BorderRadius.all(Radius.circular(widget.screenHeight * 0.03)),
                                value: pianoState.metronomeSound,
                                items: ["Click", "Woodblock"].map((s) {
                                  return DropdownMenuItem(
                                    value: s,
                                    child: Text(s,
                                        style: const TextStyle(color: Colors.white)),
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
                    ],
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
