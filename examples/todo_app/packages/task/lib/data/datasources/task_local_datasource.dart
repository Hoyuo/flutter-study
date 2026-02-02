// coverage:ignore-file
import 'package:hive/hive.dart';
import '../models/task_model.dart';
import '../../domain/usecases/get_tasks_params.dart';

/// Local data source for tasks using Hive
abstract class TaskLocalDataSource {
  /// Get a task by ID
  Future<TaskModel?> getTask(String id);

  /// Get tasks with filtering and pagination
  Future<List<TaskModel>> getTasks(GetTasksParams params);

  /// Save a task
  Future<void> saveTask(TaskModel task);

  /// Delete a task
  Future<void> deleteTask(String id);

  /// Check if a task exists
  Future<bool> taskExists(String id);

  /// Search tasks by query
  Future<List<TaskModel>> searchTasks(String query);

  /// Get task count by category
  Future<int> getTaskCountByCategory(String categoryId);
}

/// Hive implementation of TaskLocalDataSource
class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  static const String _boxName = 'tasks';
  final HiveInterface _hive;

  const TaskLocalDataSourceImpl(this._hive);

  /// Get or open the tasks box
  Future<Box<TaskModel>> get _box async {
    if (!_hive.isBoxOpen(_boxName)) {
      return await _hive.openBox<TaskModel>(_boxName);
    }
    return _hive.box<TaskModel>(_boxName);
  }

  @override
  Future<TaskModel?> getTask(String id) async {
    try {
      final box = await _box;
      return box.get(id);
    } catch (e) {
      throw Exception('Failed to get task: $e');
    }
  }

  @override
  Future<List<TaskModel>> getTasks(GetTasksParams params) async {
    try {
      final box = await _box;
      var tasks = box.values.toList();

      // Apply filters
      tasks = _applyFilters(tasks, params);

      // Apply sorting
      tasks = _applySorting(tasks, params);

      // Apply pagination
      final start = params.offset;
      final end = (start + params.limit).clamp(0, tasks.length);

      if (start >= tasks.length) {
        return [];
      }

      return tasks.sublist(start, end);
    } catch (e) {
      throw Exception('Failed to get tasks: $e');
    }
  }

  @override
  Future<void> saveTask(TaskModel task) async {
    try {
      final box = await _box;
      await box.put(task.id, task);
    } catch (e) {
      throw Exception('Failed to save task: $e');
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    try {
      final box = await _box;
      if (!box.containsKey(id)) {
        throw Exception('Task not found: $id');
      }
      await box.delete(id);
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  @override
  Future<bool> taskExists(String id) async {
    try {
      final box = await _box;
      return box.containsKey(id);
    } catch (e) {
      throw Exception('Failed to check task existence: $e');
    }
  }

  @override
  Future<List<TaskModel>> searchTasks(String query) async {
    try {
      final box = await _box;
      final lowerQuery = query.toLowerCase();
      final tasks = box.values.toList();

      return tasks.where((task) {
        return task.title.toLowerCase().contains(lowerQuery) ||
            task.description.toLowerCase().contains(lowerQuery);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search tasks: $e');
    }
  }

  @override
  Future<int> getTaskCountByCategory(String categoryId) async {
    try {
      final box = await _box;
      return box.values.where((task) => task.categoryId == categoryId).length;
    } catch (e) {
      throw Exception('Failed to get task count: $e');
    }
  }

  /// Apply filters to task list
  List<TaskModel> _applyFilters(List<TaskModel> tasks, GetTasksParams params) {
    var filtered = tasks;

    // Filter by completion status
    if (params.isCompleted != null) {
      filtered = filtered
          .where((task) => task.isCompleted == params.isCompleted)
          .toList();
    }

    // Filter by priority
    if (params.priority != null) {
      filtered = filtered
          .where((task) => task.priority == params.priority)
          .toList();
    }

    // Filter by category
    if (params.categoryId != null) {
      filtered = filtered
          .where((task) => task.categoryId == params.categoryId)
          .toList();
    }

    // Filter by today only
    if (params.todayOnly == true) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      filtered = filtered.where((task) {
        final dueDate = task.dueDate;
        if (dueDate == null) return false;
        return dueDate.isAfter(today.subtract(const Duration(seconds: 1))) &&
            dueDate.isBefore(tomorrow);
      }).toList();
    }

    return filtered;
  }

  /// Apply sorting to task list
  List<TaskModel> _applySorting(List<TaskModel> tasks, GetTasksParams params) {
    final sorted = List<TaskModel>.from(tasks);

    sorted.sort((a, b) {
      int comparison;

      switch (params.sortBy) {
        case TaskSortBy.createdAt:
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case TaskSortBy.dueDate:
          // Handle null due dates: put them at the end
          if (a.dueDate == null && b.dueDate == null) {
            comparison = 0;
          } else if (a.dueDate == null) {
            comparison = 1;
          } else if (b.dueDate == null) {
            comparison = -1;
          } else {
            comparison = a.dueDate!.compareTo(b.dueDate!);
          }
          break;
        case TaskSortBy.priority:
          comparison = b.priority.value.compareTo(a.priority.value);
          break;
        case TaskSortBy.title:
          comparison = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          break;
      }

      return params.ascending ? comparison : -comparison;
    });

    return sorted;
  }
}
