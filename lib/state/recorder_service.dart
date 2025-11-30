// state/recorder_service.dart - Updated version with persistence
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/note_event.dart';
import '../models/recording.dart';

class RecorderService extends ChangeNotifier {
  late Box<Recording> _recordingsBox;
  Recording? _currentRecording;
  Stopwatch? _stopwatch;
  bool _isRecording = false;
  int _takeCounter = 0;
  bool _isInitialized = false;

  // === Playback state ===
  bool _isPlayingRecording = false;
  bool _isPaused = false;
  int _playbackIndex = 0;
  Duration _elapsed = Duration.zero;
  String? _activeRecordingId;

  bool get isRecording => _isRecording;
  bool get isPlayingRecording => _isPlayingRecording;
  bool get isPaused => _isPaused;
  String? get activeRecordingId => _activeRecordingId;
  bool get isInitialized => _isInitialized;

  RecorderService() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      _recordingsBox = await Hive.openBox<Recording>('recordings');

      // Load take counter from preferences
      final prefsBox = await Hive.openBox('recorderPrefs');
      _takeCounter = prefsBox.get('takeCounter', defaultValue: 0);

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing RecorderService: $e');
      }
    }
  }

  Future<void> _saveTakeCounter() async {
    final prefsBox = await Hive.openBox('recorderPrefs');
    await prefsBox.put('takeCounter', _takeCounter);
  }

  void startRecording() {
    if (!_isInitialized) return;

    _isRecording = true;
    _stopwatch = Stopwatch()..start();
    _takeCounter++;
    _saveTakeCounter();

    _currentRecording = Recording(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: "Take $_takeCounter",
      createdAt: DateTime.now(),
      events: [],
    );
    notifyListeners();
  }

  Future<Recording?> stopRecording() async {
    if (!_isInitialized) return null;

    _isRecording = false;
    _stopwatch?.stop();

    if (_currentRecording != null && _currentRecording!.events.isNotEmpty) {
      // Save to Hive
      await _recordingsBox.put(_currentRecording!.id, _currentRecording!);
    }

    final finished = _currentRecording;
    _currentRecording = null;
    notifyListeners();
    return finished;
  }

  void recordNoteOn(int midiNote, int velocity) {
    if (_currentRecording == null || _stopwatch == null) return;
    _currentRecording!.events.add(
      NoteEvent(
        midiNote: midiNote,
        velocity: velocity,
        timestamp: _stopwatch!.elapsed,
        type: NoteEventType.on,
      ),
    );
  }

  void recordNoteOff(int midiNote) {
    if (_currentRecording == null || _stopwatch == null) return;
    _currentRecording!.events.add(
      NoteEvent(
        midiNote: midiNote,
        velocity: 0,
        timestamp: _stopwatch!.elapsed,
        type: NoteEventType.off,
      ),
    );
  }

  Future<void> playRecording(
      Recording recording,
      Future<void> Function(NoteEvent) playNote,
      Future<void> Function(NoteEvent) stopNote,
      ) async {
    if (_isPlayingRecording) return;

    _isPlayingRecording = true;
    _isPaused = false;
    _playbackIndex = 0;
    _elapsed = Duration.zero;
    _activeRecordingId = recording.id;
    notifyListeners();

    while (_playbackIndex < recording.events.length && _isPlayingRecording) {
      // handle pause
      if (_isPaused) {
        await Future.doWhile(() async {
          await Future.delayed(const Duration(milliseconds: 50));
          return _isPaused && _isPlayingRecording;
        });
      }

      if (!_isPlayingRecording) break;

      final event = recording.events[_playbackIndex];

      // time to wait since previous event
      final wait = _playbackIndex == 0
          ? Duration.zero
          : recording.events[_playbackIndex].timestamp -
          recording.events[_playbackIndex - 1].timestamp;

      // break long waits into small chunks so 'stopPlayback' interrupts quickly
      int remainingMs = max(0, wait.inMilliseconds);
      const int stepMs = 30; // small step
      while (remainingMs > 0 && _isPlayingRecording && !_isPaused) {
        final int stepDelay = min(stepMs, remainingMs);
        await Future.delayed(Duration(milliseconds: stepDelay));
        remainingMs -= stepDelay;
      }

      if (!_isPlayingRecording) break;
      if (_isPaused) continue; // loop back and wait while paused

      // trigger the event
      if (event.type == NoteEventType.on) {
        await playNote(event);
      } else {
        await stopNote(event);
      }

      _playbackIndex++;
    }

    // playback finished or stopped
    _isPlayingRecording = false;
    _isPaused = false;
    _playbackIndex = 0;
    _activeRecordingId = null;
    notifyListeners();
  }

  void pausePlayback() {
    if (_isPlayingRecording && !_isPaused) {
      _isPaused = true;

      notifyListeners();
    }
  }

  void resumePlayback() {
    if (_isPlayingRecording && _isPaused) {
      _isPaused = false;
      notifyListeners();
    }
  }

  void stopPlayback() {
    _isPlayingRecording = false;
    _isPaused = false;
    _playbackIndex = 0;
    _activeRecordingId = null;
    notifyListeners();
  }

  Future<void> renameRecording(String id, String newTitle) async {
    if (!_isInitialized) return;

    final recording = _recordingsBox.get(id);
    if (recording != null) {
      recording.title = newTitle;
      await recording.save();
      notifyListeners();
    }
  }

  Future<void> deleteRecording(String id) async {
    if (!_isInitialized) return;

    await _recordingsBox.delete(id);
    notifyListeners();
  }

  List<Recording> get recordings {
    if (!_isInitialized) return [];
    return _recordingsBox.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  void dispose() {
    _recordingsBox.close();
    super.dispose();
  }
}