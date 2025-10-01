

import 'package:flutter/foundation.dart';
import 'package:flutter_midi_16kb/flutter_midi_16kb.dart';
import '../services/soundfont.dart';

class MidiProvider with ChangeNotifier {
  bool isSoundfontLoaded = false;
  List<String> downloadedSoundfonts = [];

  final SoundfontService soundfontService;

  MidiProvider({required String font, required this.soundfontService}) {
    loadMidi(font); // Initialize the MIDI with the given soundfont
  }

  // Load the soundfont file and assign its ID to the variable _soundfontId
  void loadMidi(String font) async {
    if (kDebugMode) {
      print('Loading soundfont: $font');
    }

    // Ensure the soundfont is downloaded or exists locally
    await soundfontService.loadSoundfont(font);

    // Retrieve the local path of the soundfont file
    String localPath = await soundfontService.getSoundfontPath(font);
    if (kDebugMode) {
      print('Local path: $localPath');
    }

    // Print list of downloaded soundfonts
    List<String> downloadedSoundfonts = await soundfontService.getListOfLocalSoundfonts();
    if (kDebugMode) {
      print('Downloaded soundfonts: $downloadedSoundfonts');
    }
    this.downloadedSoundfonts = downloadedSoundfonts;

    // Load the soundfont using the local path
    isSoundfontLoaded = await FlutterMidi16kb.loadSoundfont(
      localPath, // Use the downloaded file path
    );
    if (kDebugMode) {
      print('Soundfont loaded: $isSoundfontLoaded');
    }

    // Indicate that the soundfont has been successfully loaded
    isSoundfontLoaded = true;
    notifyListeners(); // Notify listeners that the soundfont is ready
  }

  // Play a MIDI note with a specific key and velocity
  void playNote({
    required int midiNote,
    int channel = 0,
    int velocity = 75,
  }) {
    if (isSoundfontLoaded) {
      FlutterMidi16kb.playNote(
        channel: channel,
        key: midiNote,
        velocity: velocity,
      );
    }
  }

  // Stop a playing MIDI note
  void stopNote({
    required int midiNote,
    int channel = 0,
  }) {
    if (isSoundfontLoaded) {
      FlutterMidi16kb.stopNote(
        channel: channel,
        key: midiNote,
      );
    }
  }
}
