// models/note_event.dart
import 'package:hive/hive.dart';

part 'note_event.g.dart'; // This will be generated

enum NoteEventType { on, off }

@HiveType(typeId: 0)
class NoteEvent extends HiveObject {
  @HiveField(0)
  final int midiNote;

  @HiveField(1)
  final int velocity;

  @HiveField(2)
  final int timestampMillis; // Store as milliseconds for Hive

  @HiveField(3)
  final String typeString; // Store as String for Hive

  Duration get timestamp => Duration(milliseconds: timestampMillis);
  NoteEventType get type => typeString == 'on' ? NoteEventType.on : NoteEventType.off;

  NoteEvent({
    required this.midiNote,
    required this.velocity,
    required Duration timestamp,
    required NoteEventType type,
  }) : timestampMillis = timestamp.inMilliseconds,
        typeString = type == NoteEventType.on ? 'on' : 'off';
}
