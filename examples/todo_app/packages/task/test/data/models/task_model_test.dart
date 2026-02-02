import 'package:flutter_test/flutter_test.dart';
import 'package:core/core.dart';
import 'package:task/data/models/task_model.dart';
import 'package:task/domain/entities/task.dart' as entities;

void main() {
  group('TaskModel', () {
    final now = DateTime(2024, 1, 1);
    final dueDate = DateTime(2024, 1, 15);

    test('creates model with all fields', () {
      final model = TaskModel()
        ..id = '1'
        ..title = 'Test Task'
        ..description = 'Test Description'
        ..isCompleted = true
        ..priority = Priority.high
        ..dueDate = dueDate
        ..categoryId = 'cat-1'
        ..createdAt = now
        ..updatedAt = now;

      expect(model.id, '1');
      expect(model.title, 'Test Task');
      expect(model.description, 'Test Description');
      expect(model.isCompleted, true);
      expect(model.priority, Priority.high);
      expect(model.dueDate, dueDate);
      expect(model.categoryId, 'cat-1');
      expect(model.createdAt, now);
      expect(model.updatedAt, now);
    });

    test('priority getter returns correct Priority from value', () {
      final model = TaskModel()..priorityValue = Priority.high.value;
      expect(model.priority, Priority.high);

      model.priorityValue = Priority.medium.value;
      expect(model.priority, Priority.medium);

      model.priorityValue = Priority.low.value;
      expect(model.priority, Priority.low);
    });

    test('priority setter stores correct value', () {
      final model = TaskModel();

      model.priority = Priority.high;
      expect(model.priorityValue, Priority.high.value);

      model.priority = Priority.medium;
      expect(model.priorityValue, Priority.medium.value);

      model.priority = Priority.low;
      expect(model.priorityValue, Priority.low.value);
    });

    test('dueDate getter returns DateTime from timestamp', () {
      final model = TaskModel()
        ..dueDateTimestamp = dueDate.millisecondsSinceEpoch;

      expect(model.dueDate, dueDate);
    });

    test('dueDate getter returns null when timestamp is null', () {
      final model = TaskModel()..dueDateTimestamp = null;

      expect(model.dueDate, isNull);
    });

    test('dueDate setter stores timestamp', () {
      final model = TaskModel()..dueDate = dueDate;

      expect(model.dueDateTimestamp, dueDate.millisecondsSinceEpoch);
    });

    test('dueDate setter stores null', () {
      final model = TaskModel()..dueDate = null;

      expect(model.dueDateTimestamp, isNull);
    });

    test('createdAt getter returns DateTime from timestamp', () {
      final model = TaskModel()
        ..createdAtTimestamp = now.millisecondsSinceEpoch;

      expect(model.createdAt, now);
    });

    test('createdAt setter stores timestamp', () {
      final model = TaskModel()..createdAt = now;

      expect(model.createdAtTimestamp, now.millisecondsSinceEpoch);
    });

    test('updatedAt getter returns DateTime from timestamp', () {
      final model = TaskModel()
        ..updatedAtTimestamp = now.millisecondsSinceEpoch;

      expect(model.updatedAt, now);
    });

    test('updatedAt setter stores timestamp', () {
      final model = TaskModel()..updatedAt = now;

      expect(model.updatedAtTimestamp, now.millisecondsSinceEpoch);
    });

    test('toEntity converts model to domain entity', () {
      final model = TaskModel()
        ..id = '1'
        ..title = 'Test Task'
        ..description = 'Test Description'
        ..isCompleted = true
        ..priority = Priority.high
        ..dueDate = dueDate
        ..categoryId = 'cat-1'
        ..createdAt = now
        ..updatedAt = now;

      final entity = model.toEntity();

      expect(entity.id, '1');
      expect(entity.title, 'Test Task');
      expect(entity.description, 'Test Description');
      expect(entity.isCompleted, true);
      expect(entity.priority, Priority.high);
      expect(entity.dueDate, dueDate);
      expect(entity.categoryId, 'cat-1');
      expect(entity.createdAt, now);
      expect(entity.updatedAt, now);
    });

    test('toEntity handles null optional fields', () {
      final model = TaskModel()
        ..id = '1'
        ..title = 'Test Task'
        ..description = ''
        ..isCompleted = false
        ..priority = Priority.medium
        ..dueDate = null
        ..categoryId = null
        ..createdAt = now
        ..updatedAt = now;

      final entity = model.toEntity();

      expect(entity.dueDate, isNull);
      expect(entity.categoryId, isNull);
      expect(entity.description, '');
    });

    test('fromEntity creates model from domain entity', () {
      final entity = entities.Task(
        id: '1',
        title: 'Test Task',
        description: 'Test Description',
        isCompleted: true,
        priority: Priority.high,
        dueDate: dueDate,
        categoryId: 'cat-1',
        createdAt: now,
        updatedAt: now,
      );

      final model = TaskModel.fromEntity(entity);

      expect(model.id, '1');
      expect(model.title, 'Test Task');
      expect(model.description, 'Test Description');
      expect(model.isCompleted, true);
      expect(model.priority, Priority.high);
      expect(model.dueDate, dueDate);
      expect(model.categoryId, 'cat-1');
      expect(model.createdAt, now);
      expect(model.updatedAt, now);
    });

    test('fromEntity handles null optional fields', () {
      final entity = entities.Task(
        id: '1',
        title: 'Test Task',
        createdAt: now,
        updatedAt: now,
      );

      final model = TaskModel.fromEntity(entity);

      expect(model.dueDate, isNull);
      expect(model.categoryId, isNull);
      expect(model.description, '');
      expect(model.priority, Priority.medium);
    });

    test('copyWith creates new instance with updated fields', () {
      final model = TaskModel()
        ..id = '1'
        ..title = 'Test Task'
        ..description = 'Test Description'
        ..isCompleted = false
        ..priority = Priority.medium
        ..dueDate = null
        ..categoryId = null
        ..createdAt = now
        ..updatedAt = now;

      final updated = model.copyWith(
        title: 'Updated Task',
        isCompleted: true,
        priority: Priority.high,
        dueDate: dueDate,
        categoryId: 'cat-1',
      );

      expect(updated.id, model.id);
      expect(updated.title, 'Updated Task');
      expect(updated.isCompleted, true);
      expect(updated.priority, Priority.high);
      expect(updated.dueDate, dueDate);
      expect(updated.categoryId, 'cat-1');
      expect(updated.createdAt, model.createdAt);
    });

    test('copyWith with null values keeps original values', () {
      final model = TaskModel()
        ..id = '1'
        ..title = 'Test Task'
        ..description = 'Test Description'
        ..isCompleted = true
        ..priority = Priority.high
        ..dueDate = dueDate
        ..categoryId = 'cat-1'
        ..createdAt = now
        ..updatedAt = now;

      final updated = model.copyWith();

      expect(updated.id, model.id);
      expect(updated.title, model.title);
      expect(updated.description, model.description);
      expect(updated.isCompleted, model.isCompleted);
      expect(updated.priority, model.priority);
      expect(updated.dueDate, model.dueDate);
      expect(updated.categoryId, model.categoryId);
    });

    test('roundtrip conversion entity -> model -> entity preserves data', () {
      final originalEntity = entities.Task(
        id: '1',
        title: 'Test Task',
        description: 'Test Description',
        isCompleted: true,
        priority: Priority.high,
        dueDate: dueDate,
        categoryId: 'cat-1',
        createdAt: now,
        updatedAt: now,
      );

      final model = TaskModel.fromEntity(originalEntity);
      final restoredEntity = model.toEntity();

      expect(restoredEntity.id, originalEntity.id);
      expect(restoredEntity.title, originalEntity.title);
      expect(restoredEntity.description, originalEntity.description);
      expect(restoredEntity.isCompleted, originalEntity.isCompleted);
      expect(restoredEntity.priority, originalEntity.priority);
      expect(restoredEntity.dueDate, originalEntity.dueDate);
      expect(restoredEntity.categoryId, originalEntity.categoryId);
      expect(restoredEntity.createdAt, originalEntity.createdAt);
      expect(restoredEntity.updatedAt, originalEntity.updatedAt);
    });

    group('TaskModelAdapter', () {
      late TaskModelAdapter adapter;

      setUp(() {
        adapter = TaskModelAdapter();
      });

      test('has correct typeId', () {
        expect(adapter.typeId, 1);
      });

      test('equality works correctly', () {
        final adapter1 = TaskModelAdapter();
        final adapter2 = TaskModelAdapter();

        expect(adapter1, equals(adapter2));
        expect(adapter1.hashCode, equals(adapter2.hashCode));
      });
    });
  });
}
