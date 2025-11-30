import 'package:empyrealkeys/components/control_panel/recordings_bottom_sheet.dart';
import 'package:empyrealkeys/state/recorder_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/midi_provider.dart';
import '../../state/piano_state.dart';

class RecorderPanel extends StatefulWidget {
  final double screenWidth;
  final double screenHeight;
  const RecorderPanel({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  State<RecorderPanel> createState() => _RecorderPanelState();
}

class _RecorderPanelState extends State<RecorderPanel> {
  @override
  Widget build(BuildContext context) {
    final recorder = context.watch<RecorderService>();
    final midi = Provider.of<MidiProvider>(context, listen: false);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Recorder indicator
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Icon(
                      Icons.mic_none_rounded,
                      color: Theme.of(context).primaryColor,
                      size: widget.screenWidth * 0.025,
                    ),
                  ),

                  // Record / Stop button (for recording only)
                  IconButton(
                    iconSize: widget.screenHeight * 0.10,
                    icon: Icon(
                      recorder.isRecording
                          ? Icons.stop_rounded
                          : Icons.fiber_manual_record_rounded,
                      color: const Color(0xFF802626),
                    ),
                    onPressed: () {
                      recorder.isRecording
                          ? recorder.stopRecording()
                          : recorder.startRecording();
                    },
                  ),

                  const SizedBox(width: 10),

                  // Play / Pause button (for playback)
                  IconButton(
                    iconSize: widget.screenHeight * 0.12,
                    icon: Icon(
                      recorder.isPlayingRecording
                          ? (recorder.isPaused
                              ? Icons.play_arrow_rounded
                              : Icons.pause_rounded)
                          : Icons.play_arrow_rounded,
                      color: const Color(0xFFBCBCBC),
                    ),
                    onPressed: () {
                      if (recorder.recordings.isEmpty) return;

                      final latest = recorder.recordings.last;

                      if (!recorder.isPlayingRecording) {
                        // start playback
                        recorder.playRecording(
                          latest,
                          (event) async {
                            midi.playNote(
                              midiNote: event.midiNote,
                              velocity: event.velocity,
                            );
                          },
                          (event) async {
                            midi.stopNote(midiNote: event.midiNote);
                          },
                        );
                      } else {
                        // toggle pause/resume
                        recorder.isPaused
                            ? recorder.resumePlayback()
                            : recorder.pausePlayback();
                      }
                    },
                  ),

                  const SizedBox(width: 10),

                  // Stop button (for playback only)
                  IconButton(
                    iconSize: widget.screenHeight * 0.12,
                    icon: const Icon(
                      Icons.stop_rounded,
                      color: Color(0xFFBCBCBC),
                    ),
                    onPressed: () {
                      // Stop all active MIDI notes first
                      for (int note = 0; note < 128; note++) {
                        midi.stopNote(midiNote: note);
                      }
                      recorder.stopPlayback();
                      final pianoState = Provider.of<PianoState>(context, listen: false);
                      pianoState.clearActivePlayAlongNotes();
                    },
                  ),

                  const SizedBox(width: 15),

                  // Recordings List
                  IconButton(
                    iconSize: widget.screenHeight * 0.10,
                    icon: const Icon(
                      Icons.folder_rounded,
                      color: Color(0xFFBCBCBC),
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: const Color(0xFF2C2C2E),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                        ),
                        isScrollControlled: true,
                        builder: (context) => const RecordingsBottomSheet(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
