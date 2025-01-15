
import 'package:flutter/foundation.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';

import '../services/soundfont.dart';

class MidiProvider with ChangeNotifier {
  final MidiPro _midiPro = MidiPro();
  late int _soundfontId;
  bool isSoundfontLoaded = false;

  final SoundfontService soundfontService;

  MidiProvider({required String font, required this.soundfontService}) {
    loadMidi(font); // Initialize the MIDI with the given soundfont
  }

  // Load the soundfont file and assign its ID to the variable _soundfontId
  void loadMidi(String font) async {
    print('Loading soundfont: $font');

    // Ensure the soundfont is downloaded or exists locally
    await soundfontService.loadSoundfont(font);

    // Retrieve the local path of the soundfont file
    String localPath = await soundfontService.getSoundfontPath(font);
    print('Local path: $localPath');

    // Load the soundfont using the local path
    _soundfontId = await _midiPro.loadSoundfont(
      path: localPath, // Use the downloaded file path
      bank: 0,
      program: 0,
    );

    // Indicate that the soundfont has been successfully loaded
    isSoundfontLoaded = true;
    notifyListeners(); // Notify listeners that the soundfont is ready
  }

  // Play a MIDI note with a specific key and velocity
  void playNote({
    required int midiNote,
    int channel = 0,
    int velocity = 50,
  }) {
    if (isSoundfontLoaded) {
      _midiPro.playNote(
        sfId: _soundfontId,
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
      _midiPro.stopNote(
        sfId: _soundfontId,
        channel: channel,
        key: midiNote,
      );
    }
  }
}
