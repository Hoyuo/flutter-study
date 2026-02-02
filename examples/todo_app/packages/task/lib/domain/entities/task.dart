import 'package:core/types/priority.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'task.freezed.dart';
part 'task.g.dart';

/// Task entity representing a todo item
/// Task entity representing a todo item
@freezed
abstract class Task with _$Task {
  const Task._();

  const factory Task({
    /// Unique task identifier
    required String id,

    /// Task title
    required String title,

    /// Task description (optional)
    @Default('') String description,

    /// Completion status
    @Default(false) bool isCompleted,

    /// Task priority level
    @Default(Priority.medium) Priority priority,

    /// Due date (optional)
    DateTime? dueDate,

    /// Associated category ID (optional)
    String? categoryId,

    /// Creation timestamp
    required DateTime createdAt,

    /// Last update timestamp
    required DateTime updatedAt,
  }) = _Task;

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
}
