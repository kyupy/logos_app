// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PageDataAdapter extends TypeAdapter<PageData> {
  @override
  final int typeId = 3;

  @override
  PageData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PageData(
      strokes: (fields[0] as List).cast<StrokeData>(),
    );
  }

  @override
  void write(BinaryWriter writer, PageData obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.strokes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NoteDataAdapter extends TypeAdapter<NoteData> {
  @override
  final int typeId = 0;

  @override
  NoteData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NoteData(
      pages: (fields[0] as List).cast<PageData>(),
      createdAt: fields[1] as DateTime,
      lastOpenedPageIndex: fields[2] == null ? 0 : fields[2] as int,
      title: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, NoteData obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.pages)
      ..writeByte(1)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.lastOpenedPageIndex)
      ..writeByte(3)
      ..write(obj.title);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StrokeDataAdapter extends TypeAdapter<StrokeData> {
  @override
  final int typeId = 1;

  @override
  StrokeData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StrokeData(
      points: (fields[0] as List).cast<NotePointData>(),
    );
  }

  @override
  void write(BinaryWriter writer, StrokeData obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.points);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StrokeDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NotePointDataAdapter extends TypeAdapter<NotePointData> {
  @override
  final int typeId = 2;

  @override
  NotePointData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotePointData(
      x: fields[0] as double?,
      y: fields[1] as double?,
      pressure: fields[2] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, NotePointData obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.x)
      ..writeByte(1)
      ..write(obj.y)
      ..writeByte(2)
      ..write(obj.pressure);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotePointDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
