import 'package:category/domain/entities/category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Category Entity', () {
    final createdAt = DateTime(2024, 1, 1);

    test('should create a Category with all required fields', () {
      // Arrange & Act
      final category = Category(
        id: '1',
        name: 'Work',
        colorHex: 'FF5733',
        createdAt: createdAt,
      );

      // Assert
      expect(category.id, '1');
      expect(category.name, 'Work');
      expect(category.colorHex, 'FF5733');
      expect(category.iconName, null);
      expect(category.createdAt, createdAt);
      expect(category.taskCount, 0);
    });

    test('should create a Category with optional fields', () {
      // Arrange & Act
      final category = Category(
        id: '1',
        name: 'Work',
        colorHex: 'FF5733',
        iconName: 'work_icon',
        createdAt: createdAt,
        taskCount: 5,
      );

      // Assert
      expect(category.id, '1');
      expect(category.name, 'Work');
      expect(category.colorHex, 'FF5733');
      expect(category.iconName, 'work_icon');
      expect(category.createdAt, createdAt);
      expect(category.taskCount, 5);
    });

    test('displayColor should return formatted color with # prefix', () {
      // Arrange
      final category = Category(
        id: '1',
        name: 'Work',
        colorHex: 'FF5733',
        createdAt: createdAt,
      );

      // Act & Assert
      expect(category.displayColor, '#FF5733');
    });

    test('hasIcon should return false when iconName is null', () {
      // Arrange
      final category = Category(
        id: '1',
        name: 'Work',
        colorHex: 'FF5733',
        createdAt: createdAt,
      );

      // Act & Assert
      expect(category.hasIcon, false);
    });

    test('hasIcon should return false when iconName is empty', () {
      // Arrange
      final category = Category(
        id: '1',
        name: 'Work',
        colorHex: 'FF5733',
        iconName: '',
        createdAt: createdAt,
      );

      // Act & Assert
      expect(category.hasIcon, false);
    });

    test('hasIcon should return true when iconName is not empty', () {
      // Arrange
      final category = Category(
        id: '1',
        name: 'Work',
        colorHex: 'FF5733',
        iconName: 'work_icon',
        createdAt: createdAt,
      );

      // Act & Assert
      expect(category.hasIcon, true);
    });

    test('should support value equality', () {
      // Arrange
      final category1 = Category(
        id: '1',
        name: 'Work',
        colorHex: 'FF5733',
        iconName: 'work_icon',
        createdAt: createdAt,
        taskCount: 5,
      );

      final category2 = Category(
        id: '1',
        name: 'Work',
        colorHex: 'FF5733',
        iconName: 'work_icon',
        createdAt: createdAt,
        taskCount: 5,
      );

      // Act & Assert
      expect(category1, category2);
      expect(category1.hashCode, category2.hashCode);
    });

    test('should not be equal with different values', () {
      // Arrange
      final category1 = Category(
        id: '1',
        name: 'Work',
        colorHex: 'FF5733',
        createdAt: createdAt,
      );

      final category2 = Category(
        id: '2',
        name: 'Personal',
        colorHex: '33FF57',
        createdAt: createdAt,
      );

      // Act & Assert
      expect(category1, isNot(category2));
    });

    test('copyWith should create a new instance with updated fields', () {
      // Arrange
      final category = Category(
        id: '1',
        name: 'Work',
        colorHex: 'FF5733',
        createdAt: createdAt,
        taskCount: 0,
      );

      // Act
      final updated = category.copyWith(
        name: 'Updated Work',
        taskCount: 10,
      );

      // Assert
      expect(updated.id, '1');
      expect(updated.name, 'Updated Work');
      expect(updated.colorHex, 'FF5733');
      expect(updated.taskCount, 10);
      expect(updated.createdAt, createdAt);
    });
  });
}
