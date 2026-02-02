import 'package:flutter_test/flutter_test.dart';
import 'package:core/core.dart';
import 'package:task/domain/usecases/get_tasks_params.dart';

void main() {
  group('GetTasksParams', () {
    test('creates instance with default values', () {
      const params = GetTasksParams();

      expect(params.limit, 20);
      expect(params.offset, 0);
      expect(params.isCompleted, isNull);
      expect(params.priority, isNull);
      expect(params.categoryId, isNull);
      expect(params.sortBy, TaskSortBy.createdAt);
      expect(params.ascending, false);
      expect(params.todayOnly, isNull);
    });

    test('creates instance with custom values', () {
      const params = GetTasksParams(
        limit: 10,
        offset: 5,
        isCompleted: true,
        priority: Priority.high,
        categoryId: 'cat-1',
        sortBy: TaskSortBy.priority,
        ascending: true,
        todayOnly: true,
      );

      expect(params.limit, 10);
      expect(params.offset, 5);
      expect(params.isCompleted, true);
      expect(params.priority, Priority.high);
      expect(params.categoryId, 'cat-1');
      expect(params.sortBy, TaskSortBy.priority);
      expect(params.ascending, true);
      expect(params.todayOnly, true);
    });

    test('defaults() constructor creates instance with default values', () {
      const params = GetTasksParams.defaults();

      expect(params.limit, 20);
      expect(params.offset, 0);
      expect(params.isCompleted, isNull);
      expect(params.priority, isNull);
      expect(params.categoryId, isNull);
      expect(params.sortBy, TaskSortBy.createdAt);
      expect(params.ascending, false);
      expect(params.todayOnly, isNull);
    });

    test('copyWith returns new instance with updated values', () {
      const params = GetTasksParams();

      final updated = params.copyWith(
        limit: 10,
        offset: 5,
        isCompleted: true,
        priority: Priority.high,
        categoryId: 'cat-1',
        sortBy: TaskSortBy.priority,
        ascending: true,
        todayOnly: true,
      );

      expect(updated.limit, 10);
      expect(updated.offset, 5);
      expect(updated.isCompleted, true);
      expect(updated.priority, Priority.high);
      expect(updated.categoryId, 'cat-1');
      expect(updated.sortBy, TaskSortBy.priority);
      expect(updated.ascending, true);
      expect(updated.todayOnly, true);
    });

    test('copyWith preserves original values when null', () {
      const params = GetTasksParams(
        limit: 10,
        offset: 5,
        isCompleted: true,
        priority: Priority.high,
        categoryId: 'cat-1',
        sortBy: TaskSortBy.priority,
        ascending: true,
        todayOnly: true,
      );

      final updated = params.copyWith();

      expect(updated.limit, params.limit);
      expect(updated.offset, params.offset);
      expect(updated.isCompleted, params.isCompleted);
      expect(updated.priority, params.priority);
      expect(updated.categoryId, params.categoryId);
      expect(updated.sortBy, params.sortBy);
      expect(updated.ascending, params.ascending);
      expect(updated.todayOnly, params.todayOnly);
    });

    test('clearFilters clears all filter values but keeps pagination and sort', () {
      const params = GetTasksParams(
        limit: 10,
        offset: 5,
        isCompleted: true,
        priority: Priority.high,
        categoryId: 'cat-1',
        sortBy: TaskSortBy.priority,
        ascending: true,
        todayOnly: true,
      );

      final cleared = params.clearFilters();

      expect(cleared.limit, params.limit);
      expect(cleared.offset, 0);
      expect(cleared.isCompleted, isNull);
      expect(cleared.priority, isNull);
      expect(cleared.categoryId, isNull);
      expect(cleared.sortBy, params.sortBy);
      expect(cleared.ascending, params.ascending);
      expect(cleared.todayOnly, isNull);
    });

    test('equality works correctly', () {
      const params1 = GetTasksParams(
        limit: 10,
        offset: 5,
        isCompleted: true,
        priority: Priority.high,
        categoryId: 'cat-1',
        sortBy: TaskSortBy.priority,
        ascending: true,
        todayOnly: true,
      );

      const params2 = GetTasksParams(
        limit: 10,
        offset: 5,
        isCompleted: true,
        priority: Priority.high,
        categoryId: 'cat-1',
        sortBy: TaskSortBy.priority,
        ascending: true,
        todayOnly: true,
      );

      const params3 = GetTasksParams(
        limit: 20,
        offset: 5,
      );

      expect(params1, equals(params2));
      expect(params1, isNot(equals(params3)));
    });

    test('props returns all fields', () {
      const params = GetTasksParams(
        limit: 10,
        offset: 5,
        isCompleted: true,
        priority: Priority.high,
        categoryId: 'cat-1',
        sortBy: TaskSortBy.priority,
        ascending: true,
        todayOnly: true,
      );

      expect(
        params.props,
        [
          10,
          5,
          true,
          Priority.high,
          'cat-1',
          TaskSortBy.priority,
          true,
          true,
        ],
      );
    });
  });

  group('TaskSortBy', () {
    test('has all sort options', () {
      expect(TaskSortBy.values, [
        TaskSortBy.createdAt,
        TaskSortBy.dueDate,
        TaskSortBy.priority,
        TaskSortBy.title,
      ]);
    });
  });
}
