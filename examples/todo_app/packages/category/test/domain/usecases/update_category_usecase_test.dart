import 'package:category/domain/entities/category.dart';
import 'package:category/domain/repositories/category_repository.dart';
import 'package:category/domain/usecases/update_category_usecase.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late UpdateCategoryUseCase useCase;
  late MockCategoryRepository mockRepository;

  setUp(() {
    mockRepository = MockCategoryRepository();
    useCase = UpdateCategoryUseCase(mockRepository);
  });

  setUpAll(() {
    registerFallbackValue(Category(
      id: '1',
      name: 'Test',
      colorHex: 'FF5733',
      createdAt: DateTime(2024, 1, 1),
    ));
  });

  group('UpdateCategoryUseCase', () {
    final tCategory = Category(
      id: '1',
      name: 'Updated Work',
      colorHex: 'FF5733',
      createdAt: DateTime(2024, 1, 1),
      taskCount: 5,
    );

    test('should update a category through the repository', () async {
      // Arrange
      when(() => mockRepository.updateCategory(any()))
          .thenAnswer((_) async => Right(tCategory));

      // Act
      final result = await useCase(UpdateCategoryParams(tCategory));

      // Assert
      expect(result, Right(tCategory));
      verify(() => mockRepository.updateCategory(tCategory)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return validation failure when category is invalid', () async {
      // Arrange
      const tFailure = Failure.validation(
        message: 'Category name cannot be empty',
        field: 'name',
      );
      when(() => mockRepository.updateCategory(any()))
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(UpdateCategoryParams(tCategory));

      // Assert
      expect(result, const Left(tFailure));
      verify(() => mockRepository.updateCategory(tCategory)).called(1);
    });

    test('should return not found failure when category does not exist', () async {
      // Arrange
      const tFailure = Failure.notFound(
        message: 'Category not found',
      );
      when(() => mockRepository.updateCategory(any()))
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(UpdateCategoryParams(tCategory));

      // Assert
      expect(result, const Left(tFailure));
      verify(() => mockRepository.updateCategory(tCategory)).called(1);
    });

    test('should return database failure when repository fails', () async {
      // Arrange
      const tFailure = Failure.database(
        message: 'Failed to update category',
        exception: null,
      );
      when(() => mockRepository.updateCategory(any()))
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(UpdateCategoryParams(tCategory));

      // Assert
      expect(result, const Left(tFailure));
      verify(() => mockRepository.updateCategory(tCategory)).called(1);
    });
  });
}
