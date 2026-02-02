import 'package:category/domain/entities/category.dart';
import 'package:category/domain/repositories/category_repository.dart';
import 'package:category/domain/usecases/get_category_by_id_usecase.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late GetCategoryByIdUseCase useCase;
  late MockCategoryRepository mockRepository;

  setUp(() {
    mockRepository = MockCategoryRepository();
    useCase = GetCategoryByIdUseCase(mockRepository);
  });

  group('GetCategoryByIdUseCase', () {
    const tCategoryId = '1';
    final tCategory = Category(
      id: tCategoryId,
      name: 'Work',
      colorHex: 'FF5733',
      createdAt: DateTime(2024, 1, 1),
    );

    test('should get category by ID from the repository', () async {
      // Arrange
      when(() => mockRepository.getCategoryById(any()))
          .thenAnswer((_) async => Right(tCategory));

      // Act
      final result = await useCase(const GetCategoryByIdParams(tCategoryId));

      // Assert
      expect(result, Right(tCategory));
      verify(() => mockRepository.getCategoryById(tCategoryId)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return validation failure when ID is empty', () async {
      // Arrange
      const tFailure = Failure.validation(
        message: 'Category ID cannot be empty',
        field: 'id',
      );
      when(() => mockRepository.getCategoryById(any()))
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(const GetCategoryByIdParams(''));

      // Assert
      expect(result, const Left(tFailure));
      verify(() => mockRepository.getCategoryById('')).called(1);
    });

    test('should return not found failure when category does not exist', () async {
      // Arrange
      const tFailure = Failure.notFound(
        message: 'Category not found',
      );
      when(() => mockRepository.getCategoryById(any()))
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(const GetCategoryByIdParams(tCategoryId));

      // Assert
      expect(result, const Left(tFailure));
      verify(() => mockRepository.getCategoryById(tCategoryId)).called(1);
    });

    test('should return database failure when repository fails', () async {
      // Arrange
      const tFailure = Failure.database(
        message: 'Failed to get category by ID',
        exception: null,
      );
      when(() => mockRepository.getCategoryById(any()))
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(const GetCategoryByIdParams(tCategoryId));

      // Assert
      expect(result, const Left(tFailure));
      verify(() => mockRepository.getCategoryById(tCategoryId)).called(1);
    });
  });
}
