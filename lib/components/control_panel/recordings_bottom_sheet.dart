import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/recorder_service.dart';
import '../../state/midi_provider.dart';

class RecordingsBottomSheet extends StatelessWidget {
  const RecordingsBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final recorder = context.watch<RecorderService>();
    final midi = Provider.of<MidiProvider>(context, listen: false);

    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 6),
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 50,
              height: 5,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                // color: Colors.grey[700],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          const Text(
            "Recordings",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: recorder.recordings.isEmpty
                ? Center(
              child: Text(
                "No recordings yet",
                style: TextStyle(color: Colors.grey[400], fontSize: 16),
              ),
            )
                : ListView.builder(
              itemCount: recorder.recordings.length,
              itemBuilder: (context, index) {
                final recording = recorder.recordings[index];

                return GestureDetector(
                  onLongPress: () async {
                    final action = await showModalBottomSheet<String>(
                      context: context,
                      backgroundColor: const Color(0xFF2C2C2E),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (context) {
                        return SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.edit, color: Colors.white),
                                title: const Text("Rename", style: TextStyle(color: Colors.white)),
                                onTap: () => Navigator.pop(context, "rename"),
                              ),
                              ListTile(
                                leading: const Icon(Icons.delete, color: Colors.red),
                                title: const Text("Delete", style: TextStyle(color: Colors.red)),
                                onTap: () => Navigator.pop(context, "delete"),
                              ),
                            ],
                          ),
                        );
                      },
                    );

                    if (action == "delete") {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: const Color(0xFF2C2C2E),
                          title: const Text("Delete Recording?", style: TextStyle(color: Colors.white)),
                          content: Text(
                            "Are you sure you want to delete \"${recording.title}\"?",
                            style: const TextStyle(color: Colors.grey),
                          ),
                          actions: [
                            TextButton(
                              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                              onPressed: () => Navigator.pop(context, false),
                            ),
                            TextButton(
                              child: const Text("Delete", style: TextStyle(color: Colors.red)),
                              onPressed: () => Navigator.pop(context, true),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) recorder.deleteRecording(recording.id);
                    } else if (action == "rename") {
                      final controller = TextEditingController(text: recording.title);
                      final newTitle = await showDialog<String>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: const Color(0xFF2C2C2E),
                          title: const Text("Rename Recording", style: TextStyle(color: Colors.white)),
                          content: TextField(
                            controller: controller,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: "Enter new name",
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                          ),
                          actions: [
                            TextButton(
                              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                              onPressed: () => Navigator.pop(context, null),
                            ),
                            TextButton(
                              child: const Text("Save", style: TextStyle(color: Colors.blue)),
                              onPressed: () => Navigator.pop(context, controller.text.trim()),
                            ),
                          ],
                        ),
                      );

                      if (newTitle != null && newTitle.isNotEmpty) {
                        recorder.renameRecording(recording.id, newTitle);
                      }
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Info
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recording.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${(recording.events.length/2).toStringAsFixed(0)} notes • ${recording.createdAt.toLocal()}",
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),

                        // Play / Pause & Stop controls
                        Row(
                          children: [
                            IconButton(
                              iconSize: MediaQuery.sizeOf(context).width * 0.03,
                              icon: Icon(
                                recorder.isPlayingRecording && recorder.activeRecordingId == recording.id
                                    ? (recorder.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded)
                                    : Icons.play_arrow_rounded,
                                color: const Color(0xFFBCBCBC),
                              ),
                              onPressed: () async {
                                if (!recorder.isPlayingRecording) {
                                  await recorder.playRecording(
                                    recording,
                                        (event) async {
                                      midi.playNote(
                                        midiNote: event.midiNote,
                                        velocity: event.velocity,
                                      );
                                    },
                                        (event) async {
                                      midi.stopNote(
                                          midiNote: event.midiNote);
                                    },
                                  );
                                } else if (recorder.activeRecordingId == recording.id) {
                                  recorder.isPaused
                                      ? recorder.resumePlayback()
                                      : recorder.pausePlayback();
                                } else {
                                  // stop current and play this one
                                  recorder.stopPlayback();
                                  recorder.playRecording(
                                    recording,
                                        (event) async {
                                      midi.playNote(midiNote: event.midiNote, velocity: event.velocity);
                                    },
                                        (event) async {
                                      midi.stopNote(midiNote: event.midiNote);
                                    },
                                  );
                                }
                              },
                            ),
                            IconButton(
                              iconSize: MediaQuery.sizeOf(context).width * 0.03,
                              icon: const Icon(
                                Icons.stop_rounded,
                                color: Color(0xFFBCBCBC),
                              ),
                              onPressed: () {
                                recorder.stopPlayback();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
