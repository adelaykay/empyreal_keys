// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_event.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NoteEventAdapter extends TypeAdapter<NoteEvent> {
  @override
  final int typeId = 0;

  @override
  NoteEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NoteEvent(
      midiNote: fields[0] as int,
      velocity: fields[1] as int,
      timestamp: Duration(milliseconds: fields[2] as int),
      type: fields[3] == 'on' ? NoteEventType.on : NoteEventType.off,
    );
  }

  @override
  void write(BinaryWriter writer, NoteEvent obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.midiNote)
      ..writeByte(1)
      ..write(obj.velocity)
      ..writeByte(2)
      ..write(obj.timestampMillis)
      ..writeByte(3)
      ..write(obj.typeString);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteEventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
