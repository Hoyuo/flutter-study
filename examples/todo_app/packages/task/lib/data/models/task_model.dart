import 'package:hive/hive.dart';
import 'package:core/core.dart';
import '../../domain/entities/task.dart' as entities;

/// Hive model for Task
class TaskModel extends HiveObject {
  /// Unique task identifier
  late String id;

  /// Task title
  late String title;

  /// Task description
  late String description;

  /// Completion status
  late bool isCompleted;

  /// Priority value (stored as int)
  late int priorityValue;

  /// Due date timestamp (milliseconds since epoch, null if not set)
  int? dueDateTimestamp;

  /// Associated category ID (optional)
  String? categoryId;

  /// Creation timestamp (milliseconds since epoch)
  late int createdAtTimestamp;

  /// Last update timestamp (milliseconds since epoch)
  late int updatedAtTimestamp;

  /// Default constructor
  TaskModel();

  /// Get Priority from stored int value
  Priority get priority => Priority.fromValue(priorityValue);

  /// Set Priority by storing its int value
  set priority(Priority value) => priorityValue = value.value;

  /// Get DateTime from stored timestamp
  DateTime? get dueDate => dueDateTimestamp != null
      ? DateTime.fromMillisecondsSinceEpoch(dueDateTimestamp!)
      : null;

  /// Set DateTime by storing its timestamp
  set dueDate(DateTime? value) =>
      dueDateTimestamp = value?.millisecondsSinceEpoch;

  /// Get DateTime from stored timestamp
  DateTime get createdAt =>
      DateTime.fromMillisecondsSinceEpoch(createdAtTimestamp);

  /// Set DateTime by storing its timestamp
  set createdAt(DateTime value) =>
      createdAtTimestamp = value.millisecondsSinceEpoch;

  /// Get DateTime from stored timestamp
  DateTime get updatedAt =>
      DateTime.fromMillisecondsSinceEpoch(updatedAtTimestamp);

  /// Set DateTime by storing its timestamp
  set updatedAt(DateTime value) =>
      updatedAtTimestamp = value.millisecondsSinceEpoch;

  /// Convert model to domain entity
  entities.Task toEntity() {
    return entities.Task(
      id: id,
      title: title,
      description: description,
      isCompleted: isCompleted,
      priority: priority,
      dueDate: dueDate,
      categoryId: categoryId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Create model from domain entity
  static TaskModel fromEntity(entities.Task task) {
    return TaskModel()
      ..id = task.id
      ..title = task.title
      ..description = task.description
      ..isCompleted = task.isCompleted
      ..priority = task.priority
      ..dueDate = task.dueDate
      ..categoryId = task.categoryId
      ..createdAt = task.createdAt
      ..updatedAt = task.updatedAt;
  }

  /// Create a copy with updated fields
  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    Priority? priority,
    DateTime? dueDate,
    String? categoryId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskModel()
      ..id = id ?? this.id
      ..title = title ?? this.title
      ..description = description ?? this.description
      ..isCompleted = isCompleted ?? this.isCompleted
      ..priority = priority ?? this.priority
      ..dueDate = dueDate ?? this.dueDate
      ..categoryId = categoryId ?? this.categoryId
      ..createdAt = createdAt ?? this.createdAt
      ..updatedAt = updatedAt ?? this.updatedAt;
  }
}

/// Hive TypeAdapter for TaskModel
class TaskModelAdapter extends TypeAdapter<TaskModel> {
  @override
  final int typeId = 1;

  // coverage:ignore-start
  @override
  TaskModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return TaskModel()
      ..id = fields[0] as String
      ..title = fields[1] as String
      ..description = fields[2] as String? ?? ''
      ..isCompleted = fields[3] as bool? ?? false
      ..priorityValue = fields[4] as int? ?? 1
      ..dueDateTimestamp = fields[5] as int?
      ..categoryId = fields[6] as String?
      ..createdAtTimestamp = fields[7] as int? ?? 0
      ..updatedAtTimestamp = fields[8] as int? ?? 0;
  }

  @override
  void write(BinaryWriter writer, TaskModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.isCompleted)
      ..writeByte(4)
      ..write(obj.priorityValue)
      ..writeByte(5)
      ..write(obj.dueDateTimestamp)
      ..writeByte(6)
      ..write(obj.categoryId)
      ..writeByte(7)
      ..write(obj.createdAtTimestamp)
      ..writeByte(8)
      ..write(obj.updatedAtTimestamp);
  }
  // coverage:ignore-end

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
