// models/recording.dart
import 'package:hive/hive.dart';
import 'note_event.dart';

part 'recording.g.dart'; // This will be generated

@HiveType(typeId: 1)
class Recording extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  final List<NoteEvent> events;

  @HiveField(4)
  bool loopPlayback;

  @HiveField(5)
  String instrument;

  @HiveField(6)
  bool alignWithMetronome;

  Recording({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.events,
    this.loopPlayback = false,
    this.instrument = "piano",
    this.alignWithMetronome = false,
  });

  Recording copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    List<NoteEvent>? events,
    bool? loopPlayback,
    String? instrument,
    bool? alignWithMetronome,
  }) {
    return Recording(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      events: events ?? this.events,
      loopPlayback: loopPlayback ?? this.loopPlayback,
      instrument: instrument ?? this.instrument,
      alignWithMetronome: alignWithMetronome ?? this.alignWithMetronome,
    );
  }
}