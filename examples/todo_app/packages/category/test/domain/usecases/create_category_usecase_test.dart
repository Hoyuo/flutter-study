import 'package:category/domain/entities/category.dart';
import 'package:category/domain/repositories/category_repository.dart';
import 'package:category/domain/usecases/create_category_usecase.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late CreateCategoryUseCase useCase;
  late MockCategoryRepository mockRepository;

  setUp(() {
    mockRepository = MockCategoryRepository();
    useCase = CreateCategoryUseCase(mockRepository);
  });

  setUpAll(() {
    registerFallbackValue(Category(
      id: '1',
      name: 'Test',
      colorHex: 'FF5733',
      createdAt: DateTime(2024, 1, 1),
    ));
  });

  group('CreateCategoryUseCase', () {
    final tCategory = Category(
      id: '1',
      name: 'Work',
      colorHex: 'FF5733',
      createdAt: DateTime(2024, 1, 1),
    );

    test('should create a category through the repository', () async {
      // Arrange
      when(() => mockRepository.createCategory(any()))
          .thenAnswer((_) async => Right(tCategory));

      // Act
      final result = await useCase(CreateCategoryParams(tCategory));

      // Assert
      expect(result, Right(tCategory));
      verify(() => mockRepository.createCategory(tCategory)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return validation failure when category is invalid', () async {
      // Arrange
      const tFailure = Failure.validation(
        message: 'Category name cannot be empty',
        field: 'name',
      );
      when(() => mockRepository.createCategory(any()))
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(CreateCategoryParams(tCategory));

      // Assert
      expect(result, const Left(tFailure));
      verify(() => mockRepository.createCategory(tCategory)).called(1);
    });

    test('should return database failure when repository fails', () async {
      // Arrange
      const tFailure = Failure.database(
        message: 'Failed to create category',
        exception: null,
      );
      when(() => mockRepository.createCategory(any()))
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(CreateCategoryParams(tCategory));

      // Assert
      expect(result, const Left(tFailure));
      verify(() => mockRepository.createCategory(tCategory)).called(1);
    });

    test('should return failure when category already exists', () async {
      // Arrange
      const tFailure = Failure.validation(
        message: 'Category with this ID already exists',
        field: 'id',
      );
      when(() => mockRepository.createCategory(any()))
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(CreateCategoryParams(tCategory));

      // Assert
      expect(result, const Left(tFailure));
      verify(() => mockRepository.createCategory(tCategory)).called(1);
    });
  });
}
