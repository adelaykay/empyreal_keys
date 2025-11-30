// models/recording.dart (Extended version)
import 'package:hive/hive.dart';
import 'note_event.dart';

part 'recording.g.dart';

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

  // NEW FIELDS for music notation
  @HiveField(7)
  int timeSignatureNumerator;

  @HiveField(8)
  int timeSignatureDenominator;

  @HiveField(9)
  int keySignatureSharps; // Positive for sharps, negative for flats

  @HiveField(10)
  bool keySignatureIsMinor;

  @HiveField(11)
  double beatsPerMinute; // Tempo

  @HiveField(12)
  int ticksPerQuarterNote; // MIDI resolution

  Recording({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.events,
    this.loopPlayback = false,
    this.instrument = "piano",
    this.alignWithMetronome = false,
    this.timeSignatureNumerator = 4,
    this.timeSignatureDenominator = 4,
    this.keySignatureSharps = 0,
    this.keySignatureIsMinor = false,
    this.beatsPerMinute = 120.0,
    this.ticksPerQuarterNote = 480,
  });

  Recording copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    List<NoteEvent>? events,
    bool? loopPlayback,
    String? instrument,
    bool? alignWithMetronome,
    int? timeSignatureNumerator,
    int? timeSignatureDenominator,
    int? keySignatureSharps,
    bool? keySignatureIsMinor,
    double? beatsPerMinute,
    int? ticksPerQuarterNote,
  }) {
    return Recording(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      events: events ?? this.events,
      loopPlayback: loopPlayback ?? this.loopPlayback,
      instrument: instrument ?? this.instrument,
      alignWithMetronome: alignWithMetronome ?? this.alignWithMetronome,
      timeSignatureNumerator: timeSignatureNumerator ?? this.timeSignatureNumerator,
      timeSignatureDenominator: timeSignatureDenominator ?? this.timeSignatureDenominator,
      keySignatureSharps: keySignatureSharps ?? this.keySignatureSharps,
      keySignatureIsMinor: keySignatureIsMinor ?? this.keySignatureIsMinor,
      beatsPerMinute: beatsPerMinute ?? this.beatsPerMinute,
      ticksPerQuarterNote: ticksPerQuarterNote ?? this.ticksPerQuarterNote,
    );
  }
}