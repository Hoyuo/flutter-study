import 'package:category/domain/entities/category.dart';
import 'package:category/domain/repositories/category_repository.dart';
import 'package:category/domain/usecases/get_categories_usecase.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late GetCategoriesUseCase useCase;
  late MockCategoryRepository mockRepository;

  setUp(() {
    mockRepository = MockCategoryRepository();
    useCase = GetCategoriesUseCase(mockRepository);
  });

  group('GetCategoriesUseCase', () {
    final tCategories = [
      Category(
        id: '1',
        name: 'Work',
        colorHex: 'FF5733',
        createdAt: DateTime(2024, 1, 1),
      ),
      Category(
        id: '2',
        name: 'Personal',
        colorHex: '33FF57',
        createdAt: DateTime(2024, 1, 2),
      ),
    ];

    test('should get categories from the repository', () async {
      // Arrange
      when(() => mockRepository.getCategories())
          .thenAnswer((_) async => Right(tCategories));

      // Act
      final result = await useCase(const NoParams());

      // Assert
      expect(result, Right(tCategories));
      verify(() => mockRepository.getCategories()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return failure when repository fails', () async {
      // Arrange
      const tFailure = Failure.database(
        message: 'Failed to get categories',
        exception: null,
      );
      when(() => mockRepository.getCategories())
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(const NoParams());

      // Assert
      expect(result, const Left(tFailure));
      verify(() => mockRepository.getCategories()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return empty list when no categories exist', () async {
      // Arrange
      when(() => mockRepository.getCategories())
          .thenAnswer((_) async => const Right([]));

      // Act
      final result = await useCase(const NoParams());

      // Assert
      expect(result, const Right<Failure, List<Category>>([]));
      verify(() => mockRepository.getCategories()).called(1);
    });
  });
}
