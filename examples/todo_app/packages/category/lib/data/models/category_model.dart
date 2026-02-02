import 'package:hive/hive.dart';
import '../../domain/entities/category.dart';

/// Hive model for Category
class CategoryModel extends HiveObject {
  /// Unique category identifier
  late String id;

  /// Category name
  late String name;

  /// Color in hex format (without # prefix)
  late String colorHex;

  /// Optional icon name
  String? iconName;

  /// Creation timestamp
  late DateTime createdAt;

  /// Number of tasks in this category
  late int taskCount;

  /// Default constructor
  CategoryModel();

  /// Convert model to domain entity
  Category toEntity() {
    return Category(
      id: id,
      name: name,
      colorHex: colorHex,
      iconName: iconName,
      createdAt: createdAt,
      taskCount: taskCount,
    );
  }

  /// Create model from domain entity
  static CategoryModel fromEntity(Category category) {
    return CategoryModel()
      ..id = category.id
      ..name = category.name
      ..colorHex = category.colorHex
      ..iconName = category.iconName
      ..createdAt = category.createdAt
      ..taskCount = category.taskCount;
  }

  /// Create a copy with updated fields
  CategoryModel copyWith({
    String? id,
    String? name,
    String? colorHex,
    String? iconName,
    DateTime? createdAt,
    int? taskCount,
  }) {
    return CategoryModel()
      ..id = id ?? this.id
      ..name = name ?? this.name
      ..colorHex = colorHex ?? this.colorHex
      ..iconName = iconName ?? this.iconName
      ..createdAt = createdAt ?? this.createdAt
      ..taskCount = taskCount ?? this.taskCount;
  }
}

/// Hive TypeAdapter for CategoryModel
class CategoryModelAdapter extends TypeAdapter<CategoryModel> {
  @override
  final int typeId = 0;

  @override
  CategoryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return CategoryModel()
      ..id = fields[0] as String
      ..name = fields[1] as String
      ..colorHex = fields[2] as String
      ..iconName = fields[3] as String?
      ..createdAt = fields[4] as DateTime
      ..taskCount = fields[5] as int? ?? 0;
  }

  @override
  void write(BinaryWriter writer, CategoryModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.colorHex)
      ..writeByte(3)
      ..write(obj.iconName)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.taskCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
