// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recording.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecordingAdapter extends TypeAdapter<Recording> {
  @override
  final int typeId = 1;

  @override
  Recording read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Recording(
      id: fields[0] as String,
      title: fields[1] as String,
      createdAt: fields[2] as DateTime,
      events: (fields[3] as List).cast<NoteEvent>(),
      loopPlayback: fields[4] as bool,
      instrument: fields[5] as String,
      alignWithMetronome: fields[6] as bool,
      timeSignatureNumerator: fields[7] as int,
      timeSignatureDenominator: fields[8] as int,
      keySignatureSharps: fields[9] as int,
      keySignatureIsMinor: fields[10] as bool,
      beatsPerMinute: fields[11] as double,
      ticksPerQuarterNote: fields[12] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Recording obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.events)
      ..writeByte(4)
      ..write(obj.loopPlayback)
      ..writeByte(5)
      ..write(obj.instrument)
      ..writeByte(6)
      ..write(obj.alignWithMetronome)
      ..writeByte(7)
      ..write(obj.timeSignatureNumerator)
      ..writeByte(8)
      ..write(obj.timeSignatureDenominator)
      ..writeByte(9)
      ..write(obj.keySignatureSharps)
      ..writeByte(10)
      ..write(obj.keySignatureIsMinor)
      ..writeByte(11)
      ..write(obj.beatsPerMinute)
      ..writeByte(12)
      ..write(obj.ticksPerQuarterNote);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecordingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
