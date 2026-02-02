import 'package:category/data/datasources/category_local_datasource.dart';
import 'package:category/data/models/category_model.dart';
import 'package:category/data/repositories/category_repository_impl.dart';
import 'package:category/domain/entities/category.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoryLocalDataSource extends Mock
    implements CategoryLocalDataSource {}

void main() {
  late CategoryRepositoryImpl repository;
  late MockCategoryLocalDataSource mockLocalDataSource;

  setUp(() {
    mockLocalDataSource = MockCategoryLocalDataSource();
    repository = CategoryRepositoryImpl(mockLocalDataSource);
  });

  group('getCategories', () {
    final tModels = [
      CategoryModel()
        ..id = '1'
        ..name = 'Work'
        ..colorHex = 'FF5733'
        ..createdAt = DateTime(2024, 1, 1)
        ..taskCount = 0,
      CategoryModel()
        ..id = '2'
        ..name = 'Personal'
        ..colorHex = '33FF57'
        ..createdAt = DateTime(2024, 1, 2)
        ..taskCount = 0,
    ];

    test('should return categories when data source succeeds', () async {
      // Arrange
      when(() => mockLocalDataSource.getCategories())
          .thenAnswer((_) async => tModels);

      // Act
      final result = await repository.getCategories();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return failure'),
        (categories) {
          expect(categories.length, 2);
          expect(categories[0].id, '1');
          expect(categories[1].id, '2');
        },
      );
      verify(() => mockLocalDataSource.getCategories()).called(1);
    });

    test('should return database failure when data source throws exception', () async {
      // Arrange
      when(() => mockLocalDataSource.getCategories())
          .thenThrow(Exception('Database error'));

      // Act
      final result = await repository.getCategories();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<DatabaseFailure>()),
        (_) => fail('Should return failure'),
      );
    });

    test('should return unknown failure when unexpected error occurs', () async {
      // Arrange
      when(() => mockLocalDataSource.getCategories())
          .thenThrow('Unexpected error');

      // Act
      final result = await repository.getCategories();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnknownFailure>()),
        (_) => fail('Should return failure'),
      );
    });
  });

  group('getCategoryById', () {
    const tId = '1';
    final tModel = CategoryModel()
      ..id = tId
      ..name = 'Work'
      ..colorHex = 'FF5733'
      ..createdAt = DateTime(2024, 1, 1)
      ..taskCount = 0;

    test('should return category when found', () async {
      // Arrange
      when(() => mockLocalDataSource.getCategoryById(any()))
          .thenAnswer((_) async => tModel);

      // Act
      final result = await repository.getCategoryById(tId);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return failure'),
        (category) {
          expect(category.id, tId);
          expect(category.name, 'Work');
        },
      );
      verify(() => mockLocalDataSource.getCategoryById(tId)).called(1);
    });

    test('should return validation failure when ID is empty', () async {
      // Act
      final result = await repository.getCategoryById('');

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect((failure as ValidationFailure).field, 'id');
        },
        (_) => fail('Should return failure'),
      );
      verifyNever(() => mockLocalDataSource.getCategoryById(any()));
    });

    test('should return not found failure when category does not exist', () async {
      // Arrange
      when(() => mockLocalDataSource.getCategoryById(any()))
          .thenAnswer((_) async => null);

      // Act
      final result = await repository.getCategoryById(tId);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<NotFoundFailure>()),
        (_) => fail('Should return failure'),
      );
    });

    test('should return database failure when data source throws exception', () async {
      // Arrange
      when(() => mockLocalDataSource.getCategoryById(any()))
          .thenThrow(Exception('Database error'));

      // Act
      final result = await repository.getCategoryById(tId);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<DatabaseFailure>()),
        (_) => fail('Should return failure'),
      );
    });

    test('should return unknown failure when unexpected error occurs', () async {
      // Arrange
      when(() => mockLocalDataSource.getCategoryById(any()))
          .thenThrow('Unexpected error');

      // Act
      final result = await repository.getCategoryById(tId);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnknownFailure>()),
        (_) => fail('Should return failure'),
      );
    });
  });

  group('createCategory', () {
    final tCategory = Category(
      id: '1',
      name: 'Work',
      colorHex: 'FF5733',
      createdAt: DateTime(2024, 1, 1),
    );

    final tModel = CategoryModel()
      ..id = '1'
      ..name = 'Work'
      ..colorHex = 'FF5733'
      ..createdAt = DateTime(2024, 1, 1)
      ..taskCount = 0;

    setUpAll(() {
      registerFallbackValue(tModel);
    });

    test('should create category when valid', () async {
      // Arrange
      when(() => mockLocalDataSource.categoryExists(any()))
          .thenAnswer((_) async => false);
      when(() => mockLocalDataSource.saveCategory(any()))
          .thenAnswer((_) async => tModel);

      // Act
      final result = await repository.createCategory(tCategory);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return failure'),
        (category) {
          expect(category.id, tCategory.id);
          expect(category.name, tCategory.name);
        },
      );
      verify(() => mockLocalDataSource.categoryExists(tCategory.id)).called(1);
      verify(() => mockLocalDataSource.saveCategory(any())).called(1);
    });

    test('should return validation failure when ID is empty', () async {
      // Arrange
      final invalidCategory = tCategory.copyWith(id: '');

      // Act
      final result = await repository.createCategory(invalidCategory);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect((failure as ValidationFailure).field, 'id');
        },
        (_) => fail('Should return failure'),
      );
      verifyNever(() => mockLocalDataSource.saveCategory(any()));
    });

    test('should return validation failure when name is empty', () async {
      // Arrange
      final invalidCategory = tCategory.copyWith(name: '  ');

      // Act
      final result = await repository.createCategory(invalidCategory);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect((failure as ValidationFailure).field, 'name');
        },
        (_) => fail('Should return failure'),
      );
    });

    test('should return validation failure when name exceeds 50 characters', () async {
      // Arrange
      final invalidCategory = tCategory.copyWith(name: 'a' * 51);

      // Act
      final result = await repository.createCategory(invalidCategory);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect((failure as ValidationFailure).field, 'name');
        },
        (_) => fail('Should return failure'),
      );
    });

    test('should return validation failure when color is invalid (wrong length)', () async {
      // Arrange
      final invalidCategory = tCategory.copyWith(colorHex: 'FF57'); // too short

      // Act
      final result = await repository.createCategory(invalidCategory);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect((failure as ValidationFailure).field, 'colorHex');
        },
        (_) => fail('Should return failure'),
      );
    });

    test('should return validation failure when color has invalid characters', () async {
      // Arrange
      final invalidCategory = tCategory.copyWith(colorHex: 'GGGGGG');

      // Act
      final result = await repository.createCategory(invalidCategory);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect((failure as ValidationFailure).field, 'colorHex');
        },
        (_) => fail('Should return failure'),
      );
    });

    test('should accept 8-character ARGB color', () async {
      // Arrange
      final categoryWithAlpha = tCategory.copyWith(colorHex: 'FFFF5733');
      when(() => mockLocalDataSource.categoryExists(any()))
          .thenAnswer((_) async => false);
      when(() => mockLocalDataSource.saveCategory(any()))
          .thenAnswer((_) async => tModel);

      // Act
      final result = await repository.createCategory(categoryWithAlpha);

      // Assert
      expect(result.isRight(), true);
    });

    test('should return validation failure when category already exists', () async {
      // Arrange
      when(() => mockLocalDataSource.categoryExists(any()))
          .thenAnswer((_) async => true);

      // Act
      final result = await repository.createCategory(tCategory);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect((failure as ValidationFailure).field, 'id');
        },
        (_) => fail('Should return failure'),
      );
      verify(() => mockLocalDataSource.categoryExists(tCategory.id)).called(1);
      verifyNever(() => mockLocalDataSource.saveCategory(any()));
    });

    test('should return database failure when data source throws exception', () async {
      // Arrange
      when(() => mockLocalDataSource.categoryExists(any()))
          .thenAnswer((_) async => false);
      when(() => mockLocalDataSource.saveCategory(any()))
          .thenThrow(Exception('Database error'));

      // Act
      final result = await repository.createCategory(tCategory);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<DatabaseFailure>()),
        (_) => fail('Should return failure'),
      );
    });

    test('should return unknown failure when unexpected error occurs', () async {
      // Arrange
      when(() => mockLocalDataSource.categoryExists(any()))
          .thenAnswer((_) async => false);
      when(() => mockLocalDataSource.saveCategory(any()))
          .thenThrow('Unexpected error');

      // Act
      final result = await repository.createCategory(tCategory);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnknownFailure>()),
        (_) => fail('Should return failure'),
      );
    });
  });

  group('updateCategory', () {
    final tCategory = Category(
      id: '1',
      name: 'Updated Work',
      colorHex: 'FF5733',
      createdAt: DateTime(2024, 1, 1),
      taskCount: 5,
    );

    final tModel = CategoryModel()
      ..id = '1'
      ..name = 'Updated Work'
      ..colorHex = 'FF5733'
      ..createdAt = DateTime(2024, 1, 1)
      ..taskCount = 5;

    setUpAll(() {
      registerFallbackValue(tModel);
    });

    test('should update category when valid', () async {
      // Arrange
      when(() => mockLocalDataSource.categoryExists(any()))
          .thenAnswer((_) async => true);
      when(() => mockLocalDataSource.updateCategory(any()))
          .thenAnswer((_) async => tModel);

      // Act
      final result = await repository.updateCategory(tCategory);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return failure'),
        (category) {
          expect(category.id, tCategory.id);
          expect(category.name, tCategory.name);
          expect(category.taskCount, 5);
        },
      );
      verify(() => mockLocalDataSource.categoryExists(tCategory.id)).called(1);
      verify(() => mockLocalDataSource.updateCategory(any())).called(1);
    });

    test('should return validation failure when category is invalid', () async {
      // Arrange
      final invalidCategory = tCategory.copyWith(name: '');

      // Act
      final result = await repository.updateCategory(invalidCategory);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('Should return failure'),
      );
    });

    test('should return not found failure when category does not exist', () async {
      // Arrange
      when(() => mockLocalDataSource.categoryExists(any()))
          .thenAnswer((_) async => false);

      // Act
      final result = await repository.updateCategory(tCategory);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<NotFoundFailure>()),
        (_) => fail('Should return failure'),
      );
      verify(() => mockLocalDataSource.categoryExists(tCategory.id)).called(1);
      verifyNever(() => mockLocalDataSource.updateCategory(any()));
    });

    test('should return database failure when data source throws exception', () async {
      // Arrange
      when(() => mockLocalDataSource.categoryExists(any()))
          .thenAnswer((_) async => true);
      when(() => mockLocalDataSource.updateCategory(any()))
          .thenThrow(Exception('Database error'));

      // Act
      final result = await repository.updateCategory(tCategory);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<DatabaseFailure>()),
        (_) => fail('Should return failure'),
      );
    });

    test('should return unknown failure when unexpected error occurs', () async {
      // Arrange
      when(() => mockLocalDataSource.categoryExists(any()))
          .thenAnswer((_) async => true);
      when(() => mockLocalDataSource.updateCategory(any()))
          .thenThrow('Unexpected error');

      // Act
      final result = await repository.updateCategory(tCategory);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnknownFailure>()),
        (_) => fail('Should return failure'),
      );
    });
  });

  group('deleteCategory', () {
    const tId = '1';

    test('should delete category when exists', () async {
      // Arrange
      when(() => mockLocalDataSource.categoryExists(any()))
          .thenAnswer((_) async => true);
      when(() => mockLocalDataSource.deleteCategory(any()))
          .thenAnswer((_) async => {});

      // Act
      final result = await repository.deleteCategory(tId);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return failure'),
        (unit) => expect(unit, unit),
      );
      verify(() => mockLocalDataSource.categoryExists(tId)).called(1);
      verify(() => mockLocalDataSource.deleteCategory(tId)).called(1);
    });

    test('should return validation failure when ID is empty', () async {
      // Act
      final result = await repository.deleteCategory('');

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect((failure as ValidationFailure).field, 'id');
        },
        (_) => fail('Should return failure'),
      );
      verifyNever(() => mockLocalDataSource.deleteCategory(any()));
    });

    test('should return not found failure when category does not exist', () async {
      // Arrange
      when(() => mockLocalDataSource.categoryExists(any()))
          .thenAnswer((_) async => false);

      // Act
      final result = await repository.deleteCategory(tId);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<NotFoundFailure>()),
        (_) => fail('Should return failure'),
      );
      verify(() => mockLocalDataSource.categoryExists(tId)).called(1);
      verifyNever(() => mockLocalDataSource.deleteCategory(any()));
    });

    test('should return database failure when data source throws exception', () async {
      // Arrange
      when(() => mockLocalDataSource.categoryExists(any()))
          .thenAnswer((_) async => true);
      when(() => mockLocalDataSource.deleteCategory(any()))
          .thenThrow(Exception('Database error'));

      // Act
      final result = await repository.deleteCategory(tId);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<DatabaseFailure>()),
        (_) => fail('Should return failure'),
      );
    });

    test('should return unknown failure when unexpected error occurs', () async {
      // Arrange
      when(() => mockLocalDataSource.categoryExists(any()))
          .thenAnswer((_) async => true);
      when(() => mockLocalDataSource.deleteCategory(any()))
          .thenThrow('Unexpected error');

      // Act
      final result = await repository.deleteCategory(tId);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnknownFailure>()),
        (_) => fail('Should return failure'),
      );
    });
  });
}
