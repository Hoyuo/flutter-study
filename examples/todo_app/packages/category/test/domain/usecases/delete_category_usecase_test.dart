import 'package:category/domain/repositories/category_repository.dart';
import 'package:category/domain/usecases/delete_category_usecase.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late DeleteCategoryUseCase useCase;
  late MockCategoryRepository mockRepository;

  setUp(() {
    mockRepository = MockCategoryRepository();
    useCase = DeleteCategoryUseCase(mockRepository);
  });

  group('DeleteCategoryUseCase', () {
    const tCategoryId = '1';

    test('should delete a category through the repository', () async {
      // Arrange
      when(() => mockRepository.deleteCategory(any()))
          .thenAnswer((_) async => const Right(unit));

      // Act
      final result = await useCase(const DeleteCategoryParams(tCategoryId));

      // Assert
      expect(result, const Right(unit));
      verify(() => mockRepository.deleteCategory(tCategoryId)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return validation failure when category ID is empty', () async {
      // Arrange
      const tFailure = Failure.validation(
        message: 'Category ID cannot be empty',
        field: 'id',
      );
      when(() => mockRepository.deleteCategory(any()))
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(const DeleteCategoryParams(''));

      // Assert
      expect(result, const Left(tFailure));
      verify(() => mockRepository.deleteCategory('')).called(1);
    });

    test('should return not found failure when category does not exist', () async {
      // Arrange
      const tFailure = Failure.notFound(
        message: 'Category not found',
      );
      when(() => mockRepository.deleteCategory(any()))
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(const DeleteCategoryParams(tCategoryId));

      // Assert
      expect(result, const Left(tFailure));
      verify(() => mockRepository.deleteCategory(tCategoryId)).called(1);
    });

    test('should return database failure when repository fails', () async {
      // Arrange
      const tFailure = Failure.database(
        message: 'Failed to delete category',
        exception: null,
      );
      when(() => mockRepository.deleteCategory(any()))
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(const DeleteCategoryParams(tCategoryId));

      // Assert
      expect(result, const Left(tFailure));
      verify(() => mockRepository.deleteCategory(tCategoryId)).called(1);
    });
  });
}
