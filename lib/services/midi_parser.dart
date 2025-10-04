// services/midi_parser.dart
import 'dart:typed_data';
import '../models/note_event.dart';
import '../models/recording.dart';

class MidiParser {
  // Parse MIDI file bytes into a Recording
  static Future<Recording> parseToRecording(
      Uint8List bytes,
      String title,
      ) async {
    final events = <NoteEvent>[];

    try {
      // Read MIDI header
      if (bytes.length < 14) throw Exception('Invalid MIDI file: too short');

      // Check for "MThd" header
      if (String.fromCharCodes(bytes.sublist(0, 4)) != 'MThd') {
        throw Exception('Invalid MIDI file: no MThd header');
      }

      // Read header chunk
      final headerLength = _readInt32(bytes, 4);
      final format = _readInt16(bytes, 8);
      final numTracks = _readInt16(bytes, 10);
      final division = _readInt16(bytes, 12);

      // Calculate ticks per beat (assuming division is positive)
      final ticksPerBeat = division & 0x7FFF;

      // Default tempo: 120 BPM = 500000 microseconds per quarter note
      int microsecondsPerQuarterNote = 500000;

      // Parse all tracks
      int offset = 14; // After header

      for (int track = 0; track < numTracks; track++) {
        if (offset + 8 > bytes.length) break;

        // Check for "MTrk" header
        if (String.fromCharCodes(bytes.sublist(offset, offset + 4)) != 'MTrk') {
          throw Exception('Invalid track header');
        }

        final trackLength = _readInt32(bytes, offset + 4);
        offset += 8;

        final trackEnd = offset + trackLength;
        int currentTick = 0;
        int lastStatus = 0;

        // Track active notes for note off events
        final Map<int, int> activeNotes = {};

        while (offset < trackEnd && offset < bytes.length) {
          // Read variable-length delta time
          final deltaResult = _readVariableLength(bytes, offset);
          final delta = deltaResult.value;
          offset = deltaResult.offset;

          currentTick += delta;

          if (offset >= bytes.length) break;

          // Read status byte
          int status = bytes[offset];

          // Handle running status
          if (status < 0x80) {
            status = lastStatus;
          } else {
            offset++;
            lastStatus = status;
          }

          final statusType = status & 0xF0;
          final channel = status & 0x0F;

          // Parse event based on status
          if (statusType == 0x90) {
            // Note On
            if (offset + 2 > bytes.length) break;
            final note = bytes[offset];
            final velocity = bytes[offset + 1];
            offset += 2;

            final timeMs = _ticksToMilliseconds(
              currentTick,
              ticksPerBeat,
              microsecondsPerQuarterNote,
            );

            if (velocity > 0) {
              events.add(NoteEvent(
                midiNote: note,
                velocity: velocity,
                timestamp: Duration(milliseconds: timeMs),
                type: NoteEventType.on,
              ));
              activeNotes[note] = timeMs;
            } else {
              // Velocity 0 is equivalent to Note Off
              events.add(NoteEvent(
                midiNote: note,
                velocity: 0,
                timestamp: Duration(milliseconds: timeMs),
                type: NoteEventType.off,
              ));
              activeNotes.remove(note);
            }
          } else if (statusType == 0x80) {
            // Note Off
            if (offset + 2 > bytes.length) break;
            final note = bytes[offset];
            final velocity = bytes[offset + 1];
            offset += 2;

            final timeMs = _ticksToMilliseconds(
              currentTick,
              ticksPerBeat,
              microsecondsPerQuarterNote,
            );

            events.add(NoteEvent(
              midiNote: note,
              velocity: velocity,
              timestamp: Duration(milliseconds: timeMs),
              type: NoteEventType.off,
            ));
            activeNotes.remove(note);
          } else if (statusType == 0xB0 || statusType == 0xE0) {
            // Control Change or Pitch Bend - skip 2 bytes
            offset += 2;
          } else if (statusType == 0xC0 || statusType == 0xD0) {
            // Program Change or Channel Pressure - skip 1 byte
            offset += 1;
          } else if (status == 0xFF) {
            // Meta event
            if (offset + 2 > bytes.length) break;
            final metaType = bytes[offset];
            offset++;

            final lengthResult = _readVariableLength(bytes, offset);
            final length = lengthResult.value;
            offset = lengthResult.offset;

            if (metaType == 0x51 && length == 3) {
              // Tempo change
              if (offset + 3 <= bytes.length) {
                microsecondsPerQuarterNote = (bytes[offset] << 16) |
                (bytes[offset + 1] << 8) |
                bytes[offset + 2];
              }
            }

            offset += length;
          } else if (status == 0xF0 || status == 0xF7) {
            // SysEx event - skip
            final lengthResult = _readVariableLength(bytes, offset);
            offset = lengthResult.offset + lengthResult.value;
          }
        }

        offset = trackEnd;
      }

      // Sort events by timestamp
      events.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    } catch (e) {
      print('MIDI parsing error: $e');
      // Return empty recording on error
    }

    return Recording(
      id: 'imported_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      createdAt: DateTime.now(),
      events: events,
      loopPlayback: false,
      instrument: 'piano',
    );
  }

  // Read 16-bit big-endian integer
  static int _readInt16(Uint8List bytes, int offset) {
    return (bytes[offset] << 8) | bytes[offset + 1];
  }

  // Read 32-bit big-endian integer
  static int _readInt32(Uint8List bytes, int offset) {
    return (bytes[offset] << 24) |
    (bytes[offset + 1] << 16) |
    (bytes[offset + 2] << 8) |
    bytes[offset + 3];
  }

  // Read variable-length quantity
  static ({int value, int offset}) _readVariableLength(
      Uint8List bytes,
      int offset,
      ) {
    int value = 0;
    int byte;

    do {
      if (offset >= bytes.length) break;
      byte = bytes[offset++];
      value = (value << 7) | (byte & 0x7F);
    } while (byte & 0x80 != 0);

    return (value: value, offset: offset);
  }

  // Convert MIDI ticks to milliseconds
  static int _ticksToMilliseconds(
      int ticks,
      int ticksPerBeat,
      int microsecondsPerQuarterNote,
      ) {
    final millisecondsPerTick = microsecondsPerQuarterNote / ticksPerBeat / 1000;
    return (ticks * millisecondsPerTick).round();
  }
}