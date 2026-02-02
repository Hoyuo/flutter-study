import 'dart:convert';
import 'dart:typed_data';

import 'package:category/data/models/category_model.dart';
import 'package:category/domain/entities/category.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  group('CategoryModel', () {
    final createdAt = DateTime(2024, 1, 1);

    test('should create a CategoryModel with all fields', () {
      // Arrange & Act
      final model = CategoryModel()
        ..id = '1'
        ..name = 'Work'
        ..colorHex = 'FF5733'
        ..iconName = 'work_icon'
        ..createdAt = createdAt
        ..taskCount = 5;

      // Assert
      expect(model.id, '1');
      expect(model.name, 'Work');
      expect(model.colorHex, 'FF5733');
      expect(model.iconName, 'work_icon');
      expect(model.createdAt, createdAt);
      expect(model.taskCount, 5);
    });

    test('toEntity should convert model to domain entity', () {
      // Arrange
      final model = CategoryModel()
        ..id = '1'
        ..name = 'Work'
        ..colorHex = 'FF5733'
        ..iconName = 'work_icon'
        ..createdAt = createdAt
        ..taskCount = 5;

      // Act
      final entity = model.toEntity();

      // Assert
      expect(entity, isA<Category>());
      expect(entity.id, '1');
      expect(entity.name, 'Work');
      expect(entity.colorHex, 'FF5733');
      expect(entity.iconName, 'work_icon');
      expect(entity.createdAt, createdAt);
      expect(entity.taskCount, 5);
    });

    test('toEntity should handle null iconName', () {
      // Arrange
      final model = CategoryModel()
        ..id = '1'
        ..name = 'Work'
        ..colorHex = 'FF5733'
        ..iconName = null
        ..createdAt = createdAt
        ..taskCount = 0;

      // Act
      final entity = model.toEntity();

      // Assert
      expect(entity.iconName, null);
      expect(entity.taskCount, 0);
    });

    test('fromEntity should convert domain entity to model', () {
      // Arrange
      final entity = Category(
        id: '1',
        name: 'Work',
        colorHex: 'FF5733',
        iconName: 'work_icon',
        createdAt: createdAt,
        taskCount: 5,
      );

      // Act
      final model = CategoryModel.fromEntity(entity);

      // Assert
      expect(model, isA<CategoryModel>());
      expect(model.id, '1');
      expect(model.name, 'Work');
      expect(model.colorHex, 'FF5733');
      expect(model.iconName, 'work_icon');
      expect(model.createdAt, createdAt);
      expect(model.taskCount, 5);
    });

    test('fromEntity should handle null iconName', () {
      // Arrange
      final entity = Category(
        id: '1',
        name: 'Work',
        colorHex: 'FF5733',
        iconName: null,
        createdAt: createdAt,
        taskCount: 0,
      );

      // Act
      final model = CategoryModel.fromEntity(entity);

      // Assert
      expect(model.iconName, null);
      expect(model.taskCount, 0);
    });

    test('copyWith should create a new model with updated fields', () {
      // Arrange
      final model = CategoryModel()
        ..id = '1'
        ..name = 'Work'
        ..colorHex = 'FF5733'
        ..iconName = 'work_icon'
        ..createdAt = createdAt
        ..taskCount = 5;

      // Act
      final updated = model.copyWith(
        name: 'Updated Work',
        taskCount: 10,
      );

      // Assert
      expect(updated.id, '1');
      expect(updated.name, 'Updated Work');
      expect(updated.colorHex, 'FF5733');
      expect(updated.iconName, 'work_icon');
      expect(updated.taskCount, 10);
    });

    test('copyWith should preserve existing fields when not updated', () {
      // Arrange
      final model = CategoryModel()
        ..id = '1'
        ..name = 'Work'
        ..colorHex = 'FF5733'
        ..iconName = 'work_icon'
        ..createdAt = createdAt
        ..taskCount = 5;

      // Act
      final updated = model.copyWith();

      // Assert
      expect(updated.id, model.id);
      expect(updated.name, model.name);
      expect(updated.colorHex, model.colorHex);
      expect(updated.iconName, model.iconName);
      expect(updated.createdAt, model.createdAt);
      expect(updated.taskCount, model.taskCount);
    });

    test('should convert entity to model and back to entity', () {
      // Arrange
      final originalEntity = Category(
        id: '1',
        name: 'Work',
        colorHex: 'FF5733',
        iconName: 'work_icon',
        createdAt: createdAt,
        taskCount: 5,
      );

      // Act
      final model = CategoryModel.fromEntity(originalEntity);
      final convertedEntity = model.toEntity();

      // Assert
      expect(convertedEntity, originalEntity);
    });
  });

  group('CategoryModelAdapter', () {
    late CategoryModelAdapter adapter;

    setUp(() {
      adapter = CategoryModelAdapter();
    });

    test('should have correct typeId', () {
      // Assert
      expect(adapter.typeId, 0);
    });

    test('should write and read CategoryModel correctly', () {
      // Arrange
      final createdAt = DateTime(2024, 1, 1);
      final model = CategoryModel()
        ..id = '1'
        ..name = 'Work'
        ..colorHex = 'FF5733'
        ..iconName = 'work_icon'
        ..createdAt = createdAt
        ..taskCount = 5;

      final writer = _FakeBinaryWriter();

      // Act - Write
      adapter.write(writer, model);

      // Assert - Write
      expect(writer.data.length, 13); // 6 fields * 2 (byte + value) + 1 count byte
      expect(writer.data[0], 6); // Number of fields
      expect(writer.data[1], 0); // id field index
      expect(writer.data[2], '1'); // id value
      expect(writer.data[3], 1); // name field index
      expect(writer.data[4], 'Work'); // name value
      expect(writer.data[5], 2); // colorHex field index
      expect(writer.data[6], 'FF5733'); // colorHex value
      expect(writer.data[7], 3); // iconName field index
      expect(writer.data[8], 'work_icon'); // iconName value
      expect(writer.data[9], 4); // createdAt field index
      expect(writer.data[10], createdAt); // createdAt value
      expect(writer.data[11], 5); // taskCount field index
      expect(writer.data[12], 5); // taskCount value

      // Act - Read
      final reader = _FakeBinaryReader(writer.data);
      final readModel = adapter.read(reader);

      // Assert - Read
      expect(readModel.id, model.id);
      expect(readModel.name, model.name);
      expect(readModel.colorHex, model.colorHex);
      expect(readModel.iconName, model.iconName);
      expect(readModel.createdAt, model.createdAt);
      expect(readModel.taskCount, model.taskCount);
    });

    test('should handle null iconName when reading', () {
      // Arrange
      final createdAt = DateTime(2024, 1, 1);
      final model = CategoryModel()
        ..id = '1'
        ..name = 'Work'
        ..colorHex = 'FF5733'
        ..iconName = null
        ..createdAt = createdAt
        ..taskCount = 5;

      final writer = _FakeBinaryWriter();

      // Act
      adapter.write(writer, model);
      final reader = _FakeBinaryReader(writer.data);
      final readModel = adapter.read(reader);

      // Assert
      expect(readModel.iconName, null);
    });

    test('should default taskCount to 0 when null', () {
      // Arrange
      final data = <dynamic>[
        6, // numOfFields
        0, '1', // id
        1, 'Work', // name
        2, 'FF5733', // colorHex
        3, null, // iconName
        4, DateTime(2024, 1, 1), // createdAt
        5, null, // taskCount (null)
      ];
      final reader = _FakeBinaryReader(data);

      // Act
      final model = adapter.read(reader);

      // Assert
      expect(model.taskCount, 0);
    });

    test('should have correct equality and hashCode', () {
      // Arrange
      final adapter1 = CategoryModelAdapter();
      final adapter2 = CategoryModelAdapter();

      // Assert
      expect(adapter1, adapter2);
      expect(adapter1.hashCode, adapter2.hashCode);
    });
  });
}

// Fake implementations for testing Hive adapter
class _FakeBinaryWriter implements BinaryWriter {
  final List<dynamic> data = [];

  
  void writeByte(int byte) => data.add(byte);

  
  void write<T>(T value, {bool writeTypeId = true}) => data.add(value);

  
  void writeString(String value,
          {bool writeByteCount = true,
          Converter<String, List<int>>? encoder}) =>
      data.add(value);

  
  void writeInt(int value) => data.add(value);

  
  void writeDouble(double value) => data.add(value);

  
  void writeBool(bool value) => data.add(value);

  
  void writeByteList(List<int> bytes, {bool writeLength = true}) =>
      data.add(bytes);

  
  void writeIntList(List<int> ints, {bool writeLength = true}) =>
      data.add(ints);

  
  void writeDoubleList(List<double> doubles, {bool writeLength = true}) =>
      data.add(doubles);

  
  void writeBoolList(List<bool> bools, {bool writeLength = true}) =>
      data.add(bools);

  
  void writeStringList(List<String> strings,
          {bool writeLength = true,
          Converter<String, List<int>>? encoder}) =>
      data.add(strings);

  
  void writeList(List list, {bool writeLength = true}) => data.add(list);

  
  void writeMap(Map map, {bool writeLength = true}) => data.add(map);

  
  void writeUint8List(List<int> bytes) => data.add(bytes);

  
  void writeInt32List(List<int> ints) => data.add(ints);

  
  void writeHiveList(HiveList list, {bool writeLength = true}) =>
      data.add(list);

  
  void writeInt32(int value) => data.add(value);

  
  void writeUint32(int value) => data.add(value);

  
  void writeWord(int value) => data.add(value);
}

class _FakeBinaryReader implements BinaryReader {
  final List<dynamic> data;
  int index = 0;

  _FakeBinaryReader(this.data);

  
  int readByte() => data[index++] as int;

  
  dynamic read([int? typeId]) => data[index++];

  
  String readString([int? length, Converter<List<int>, String>? decoder]) =>
      data[index++] as String;

  
  Uint8List peekBytes(int count) => Uint8List(count);

  
  HiveList readHiveList([int? length]) => throw UnimplementedError();

  
  int readInt32() => data[index++] as int;

  
  int readUint32() => data[index++] as int;

  
  int readWord() => data[index++] as int;

  
  int readInt() => data[index++] as int;

  
  double readDouble() => data[index++] as double;

  
  bool readBool() => data[index++] as bool;

  
  Uint8List readByteList([int? length]) => data[index++] as Uint8List;

  
  List<int> readIntList([int? length]) => data[index++] as List<int>;

  
  List<double> readDoubleList([int? length]) => data[index++] as List<double>;

  
  List<bool> readBoolList([int? length]) => data[index++] as List<bool>;

  
  List<String> readStringList(
          [int? length, Converter<List<int>, String>? decoder]) =>
      data[index++] as List<String>;

  
  List readList([int? length]) => data[index++] as List;

  
  Map readMap([int? length]) => data[index++] as Map;

  
  Uint8List readUint8List([int? length]) => data[index++] as Uint8List;

  
  Int32List readInt32List([int? length]) => data[index++] as Int32List;

  
  int get availableBytes => data.length - index;

  
  int get usedBytes => index;

  
  void skip(int bytes) => index += bytes;

  
  Uint8List viewBytes(int bytes) {
    final result = Uint8List.fromList(
        data.sublist(index, index + bytes).cast<int>());
    index += bytes;
    return result;
  }
}
