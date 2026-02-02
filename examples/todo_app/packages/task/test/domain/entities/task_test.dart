import 'package:flutter_test/flutter_test.dart';
import 'package:core/core.dart';
import 'package:task/domain/entities/task.dart';

void main() {
  group('Task', () {
    final now = DateTime(2024, 1, 1);
    final dueDate = DateTime(2024, 1, 15);

    test('creates task with required fields', () {
      final task = Task(
        id: '1',
        title: 'Test Task',
        createdAt: now,
        updatedAt: now,
      );

      expect(task.id, '1');
      expect(task.title, 'Test Task');
      expect(task.description, '');
      expect(task.isCompleted, false);
      expect(task.priority, Priority.medium);
      expect(task.dueDate, isNull);
      expect(task.categoryId, isNull);
      expect(task.createdAt, now);
      expect(task.updatedAt, now);
    });

    test('creates task with all fields', () {
      final task = Task(
        id: '1',
        title: 'Test Task',
        description: 'Test Description',
        isCompleted: true,
        priority: Priority.high,
        dueDate: dueDate,
        categoryId: 'category-1',
        createdAt: now,
        updatedAt: now,
      );

      expect(task.id, '1');
      expect(task.title, 'Test Task');
      expect(task.description, 'Test Description');
      expect(task.isCompleted, true);
      expect(task.priority, Priority.high);
      expect(task.dueDate, dueDate);
      expect(task.categoryId, 'category-1');
      expect(task.createdAt, now);
      expect(task.updatedAt, now);
    });

    test('copyWith creates new instance with updated fields', () {
      final task = Task(
        id: '1',
        title: 'Test Task',
        createdAt: now,
        updatedAt: now,
      );

      final updated = task.copyWith(
        title: 'Updated Task',
        isCompleted: true,
        priority: Priority.high,
      );

      expect(updated.id, task.id);
      expect(updated.title, 'Updated Task');
      expect(updated.isCompleted, true);
      expect(updated.priority, Priority.high);
      expect(updated.description, task.description);
      expect(updated.createdAt, task.createdAt);
    });

    test('equality works correctly', () {
      final task1 = Task(
        id: '1',
        title: 'Test Task',
        createdAt: now,
        updatedAt: now,
      );

      final task2 = Task(
        id: '1',
        title: 'Test Task',
        createdAt: now,
        updatedAt: now,
      );

      final task3 = Task(
        id: '2',
        title: 'Test Task',
        createdAt: now,
        updatedAt: now,
      );

      expect(task1, equals(task2));
      expect(task1, isNot(equals(task3)));
    });

    test('toJson and fromJson work correctly', () {
      final task = Task(
        id: '1',
        title: 'Test Task',
        description: 'Test Description',
        isCompleted: true,
        priority: Priority.high,
        dueDate: dueDate,
        categoryId: 'category-1',
        createdAt: now,
        updatedAt: now,
      );

      final json = task.toJson();
      final restored = Task.fromJson(json);

      expect(restored.id, task.id);
      expect(restored.title, task.title);
      expect(restored.description, task.description);
      expect(restored.isCompleted, task.isCompleted);
      expect(restored.priority, task.priority);
      expect(restored.dueDate, task.dueDate);
      expect(restored.categoryId, task.categoryId);
      expect(restored.createdAt, task.createdAt);
      expect(restored.updatedAt, task.updatedAt);
    });

    test('toJson handles null values correctly', () {
      final task = Task(
        id: '1',
        title: 'Test Task',
        createdAt: now,
        updatedAt: now,
      );

      final json = task.toJson();
      final restored = Task.fromJson(json);

      expect(restored.dueDate, isNull);
      expect(restored.categoryId, isNull);
      expect(restored.description, '');
    });
  });
}
