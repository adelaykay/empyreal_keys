// piano_key_listener.dart

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/midi_provider.dart';
import '../../state/piano_state.dart';

class PianoKeyListener extends StatefulWidget {
  final Widget child;
  final List<int> whiteKeyIndices;
  final List<int> blackKeyIndices;
  final List<double> blackKeyOffsets;
  final double whiteKeyWidth;
  final double blackKeyWidth;
  final int numberOfKeys;

  const PianoKeyListener({
    super.key,
    required this.child,
    required this.whiteKeyIndices,
    required this.blackKeyIndices,
    required this.blackKeyOffsets,
    required this.whiteKeyWidth,
    required this.blackKeyWidth,
    required this.numberOfKeys,
  });

  @override
  State<PianoKeyListener> createState() => _PianoKeyListenerState();
}

class _PianoKeyListenerState extends State<PianoKeyListener> {
  // Use a map to track the last played note for each pointer
  final Map<int, int> _lastPlayedNoteByPointer = {};

  // void _playNote(MidiProvider midiProvider, int midiNote, int volume) {
  //   try {
  //     midiProvider.playNote(midiNote: midiNote, velocity: volume);
  //   } catch (e) {
  //     if (kDebugMode) {
  //       print('An error occurred: $e');
  //     }
  //   }
  // }
  // void _stopNote(MidiProvider midiProvider, int midiNote) {
  //   midiProvider.stopNote(midiNote: midiNote);
  // }

  @override
  Widget build(BuildContext context) {
    final isChordMode = Provider.of<PianoState>(context, listen: false).isChordMode;
    final chordFormulas = Provider.of<PianoState>(context, listen: false).chordFormulas;
    final chordType = Provider.of<PianoState>(context, listen: false).chordType;

    void playNoteOrChord(MidiProvider midiProvider, int midiNote, int volume){
      if (isChordMode) {
        // Play a chord
        List<int> intervals = chordFormulas[chordType]!;
        for (int interval in intervals) {
          midiProvider.playNote(midiNote: midiNote + interval, velocity: volume);
        }
      } else {
        // Play a single note
        midiProvider.playNote(midiNote: midiNote, velocity: volume);
      }
    }

    void stopNoteOrChord(MidiProvider midiProvider, int midiNote) {
      if (isChordMode) {
        // Stop all notes in the chord
        List<int> intervals = chordFormulas[chordType]!;
        for (int interval in intervals) {
          midiProvider.stopNote(midiNote: midiNote + interval);
        }
      } else {
        // Stop the single note
        midiProvider.stopNote(midiNote: midiNote);
      }
    }

    return Listener(
      onPointerDown: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final Offset localPosition = box.globalToLocal(details.position);
        final Size size = box.size;
        final double keyWidth = size.width / widget.numberOfKeys;
        final double keyHeight = size.height;
        final pianoState = Provider.of<PianoState>(context, listen: false);
        final notes = pianoState.notes;
        final octave = pianoState.octave;
        final volume = pianoState.volume;
        bool blackKeyPressed = false;
        int? playedNote;
        // Check for black key presses first
        final int blackCount = min(
          widget.blackKeyIndices.length,
          widget.blackKeyOffsets.length,
        );
        for (int i = 0; i < blackCount; i++) {
          final double keyLeft = widget.whiteKeyWidth * widget.blackKeyOffsets[i];
          final double keyRight = keyLeft + widget.blackKeyWidth;
          final double keyTop = 0;
          final double keyBottom = keyHeight * 0.6; // Black keys are shorter
          int midiNote = 12 + (octave * 12) + widget.blackKeyIndices[i];
          if (localPosition.dx >= keyLeft &&
              localPosition.dx <= keyRight &&
              localPosition.dy >= keyTop &&
              localPosition.dy <= keyBottom) {
            playedNote = midiNote;
            _lastPlayedNoteByPointer[details.pointer] = midiNote;
            playNoteOrChord(Provider.of<MidiProvider>(context, listen: false), midiNote, volume);
            pianoState.setCurrentNote(notes[widget.blackKeyIndices[i]]);
            blackKeyPressed = true;
            break; // Exit loop if a black key is pressed
          }
        }
        // Check for white key presses only if no black key was pressed
        if (!blackKeyPressed) {
          for (int i = 0; i < widget.whiteKeyIndices.length; i++) {
            final double keyLeft = i * keyWidth;
            final double keyRight = (i + 1) * keyWidth;
            int midiNote = 12 + (octave * 12) + widget.whiteKeyIndices[i];
            if (localPosition.dx >= keyLeft &&
                localPosition.dx <= keyRight &&
                localPosition.dy >= 0 &&
                localPosition.dy <= keyHeight) {
              playedNote = midiNote;
              _lastPlayedNoteByPointer[details.pointer] = midiNote;
              playNoteOrChord(Provider.of<MidiProvider>(context, listen: false), midiNote, volume);
              pianoState.setCurrentNote(notes[widget.whiteKeyIndices[i]]);
            }
          }
        }
      },
      onPointerUp: (details) {
        final int? lastPlayedNote = _lastPlayedNoteByPointer.remove(details.pointer);
        if (lastPlayedNote != null) {
          stopNoteOrChord(Provider.of<MidiProvider>(context, listen: false), lastPlayedNote);
        }
        if (_lastPlayedNoteByPointer.isEmpty) {
          Provider.of<PianoState>(context, listen: false).setCurrentNote('..');
        }
      },
      onPointerMove: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final Offset localPosition = box.globalToLocal(details.position);
        final Size size = box.size;
        final double keyWidth = size.width / widget.numberOfKeys;
        final double keyHeight = size.height;
        final pianoState = Provider.of<PianoState>(context, listen: false);
        final notes = pianoState.notes;
        final octave = pianoState.octave;
        final volume = pianoState.volume;
        bool blackKeyPressed = false;
        int? playedNote;

        // Check for black key presses first
        final int blackCount = min(
          widget.blackKeyIndices.length,
          widget.blackKeyOffsets.length,
        );
        for (int i = 0; i < blackCount; i++) {
          final double keyLeft = widget.whiteKeyWidth * widget.blackKeyOffsets[i];
          final double keyRight = keyLeft + widget.blackKeyWidth;
          final double keyTop = 0;
          final double keyBottom = keyHeight * 0.6; // Black keys are shorter
          int midiNote = 12 + (octave * 12) + widget.blackKeyIndices[i];
          if (localPosition.dx >= keyLeft &&
              localPosition.dx <= keyRight &&
              localPosition.dy >= keyTop &&
              localPosition.dy <= keyBottom) {
            playedNote = midiNote;
            final int? lastPlayedNote = _lastPlayedNoteByPointer[details.pointer];
            if (midiNote != lastPlayedNote) {
              // New note, play it
              playNoteOrChord(Provider.of<MidiProvider>(context, listen: false), midiNote, volume);
              if (lastPlayedNote != null) {
                stopNoteOrChord(Provider.of<MidiProvider>(context, listen: false), lastPlayedNote);
              }
              pianoState.setCurrentNote(notes[widget.blackKeyIndices[i]]);
              _lastPlayedNoteByPointer[details.pointer] = midiNote;
            }
            blackKeyPressed = true;
            break;
          }
        }
        // Check for white key presses only if no black key was pressed
        if (!blackKeyPressed) {
          for (int i = 0; i < widget.whiteKeyIndices.length; i++) {
            final double keyLeft = i * keyWidth;
            final double keyRight = (i + 1) * keyWidth;
            int midiNote = 12 + (octave * 12) + widget.whiteKeyIndices[i];
            if (localPosition.dx >= keyLeft &&
                localPosition.dx <= keyRight &&
                localPosition.dy >= 0 &&
                localPosition.dy <= keyHeight) {
              playedNote = midiNote;
              final int? lastPlayedNote = _lastPlayedNoteByPointer[details.pointer];
              if (midiNote != lastPlayedNote) {
                playNoteOrChord(Provider.of<MidiProvider>(context, listen: false), midiNote, volume);
                if (lastPlayedNote != null) {
                  stopNoteOrChord(Provider.of<MidiProvider>(context, listen: false), lastPlayedNote);
                }
                pianoState.setCurrentNote(notes[widget.whiteKeyIndices[i]]);
                _lastPlayedNoteByPointer[details.pointer] = midiNote;
              }
            }
          }
        }
      },
      child: widget.child,
    );
  }
}