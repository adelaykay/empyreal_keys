import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../state/piano_state.dart';

class MetronomeService with ChangeNotifier {
  Timer? _timer;
  int beatCount = 0;
  bool _pendingStop = false;
  bool _isBusy = false;

  final PianoState pianoState;

  MetronomeService(this.pianoState);

  bool get isPlaying => _timer != null;

  Future<void> toggleMetronome() async {
    if (_isBusy) return;
    _isBusy = true;

    if (_timer == null) {
      start();
    } else {
      stop();
    }

    _isBusy = false;
  }


  void start() {
    stop(immediate: true);
    int beatsPerBar = int.parse(pianoState.timeSig.split("/")[0]);
    Duration interval = Duration(milliseconds: (60000 / pianoState.bpm).round());

    beatCount = 0;
    _timer = Timer.periodic(interval, (_) {
      beatCount = (beatCount % beatsPerBar) + 1;
      _playTick(pianoState.accentFirst && beatCount == 1); // strong click on first beat
      notifyListeners(); // update ui (for flashing border)

      // check if we should stop after this bar
      if (_pendingStop && beatCount == beatsPerBar) {
        stop(immediate: true);
      }
    });
  }

  void stop({bool immediate = false}) {
    if (immediate) {
      _timer?.cancel();
      _timer = null;
      _pendingStop = false;
      notifyListeners();
    } else {
      // mark stop for end of bar
      if (_timer != null) _pendingStop = true;
    }
  }

  Future<void> _playTick(bool strong) async {
    final soundPath = switch (pianoState.metronomeSound) {
      "Piano" => strong
          ? 'sounds/metronome/metronome_piano_strong.wav'
          : 'sounds/metronome/metronome_piano_soft.wav',
      "Woodblock" => strong
          ? 'sounds/metronome/metronome_woodblock_strong.wav'
          : 'sounds/metronome/metronome_woodblock_soft.wav',
      _ => strong
          ? 'sounds/metronome/metronome_click_strong.wav'
          : 'sounds/metronome/metronome_click_soft.wav',
    };

    // Create a fresh player each tick to avoid Android conflicts
    final player = AudioPlayer();
    await player.play(AssetSource(soundPath));
    player.onPlayerComplete.listen((event) => player.dispose());
  }
}
