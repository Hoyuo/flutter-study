import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:category/domain/entities/category.dart';
import 'package:category/domain/usecases/create_category_usecase.dart';
import 'package:category/domain/usecases/delete_category_usecase.dart';
import 'package:category/domain/usecases/get_categories_usecase.dart';
import 'package:category/domain/usecases/update_category_usecase.dart';
import 'package:category/presentation/bloc/category_bloc.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockGetCategoriesUseCase extends Mock implements GetCategoriesUseCase {}

class MockCreateCategoryUseCase extends Mock implements CreateCategoryUseCase {}

class MockUpdateCategoryUseCase extends Mock implements UpdateCategoryUseCase {}

class MockDeleteCategoryUseCase extends Mock implements DeleteCategoryUseCase {}

void main() {
  late CategoryBloc bloc;
  late MockGetCategoriesUseCase mockGetCategoriesUseCase;
  late MockCreateCategoryUseCase mockCreateCategoryUseCase;
  late MockUpdateCategoryUseCase mockUpdateCategoryUseCase;
  late MockDeleteCategoryUseCase mockDeleteCategoryUseCase;

  setUp(() {
    mockGetCategoriesUseCase = MockGetCategoriesUseCase();
    mockCreateCategoryUseCase = MockCreateCategoryUseCase();
    mockUpdateCategoryUseCase = MockUpdateCategoryUseCase();
    mockDeleteCategoryUseCase = MockDeleteCategoryUseCase();

    bloc = CategoryBloc(
      getCategoriesUseCase: mockGetCategoriesUseCase,
      createCategoryUseCase: mockCreateCategoryUseCase,
      updateCategoryUseCase: mockUpdateCategoryUseCase,
      deleteCategoryUseCase: mockDeleteCategoryUseCase,
    );
  });

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(CreateCategoryParams(Category(
      id: '1',
      name: 'Test',
      colorHex: 'FF5733',
      createdAt: DateTime(2024, 1, 1),
    )));
    registerFallbackValue(UpdateCategoryParams(Category(
      id: '1',
      name: 'Test',
      colorHex: 'FF5733',
      createdAt: DateTime(2024, 1, 1),
    )));
    registerFallbackValue(const DeleteCategoryParams('1'));
  });

  tearDown(() {
    bloc.close();
  });

  group('CategoryBloc', () {
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

    test('initial state should be CategoryState.initial', () {
      // Assert
      expect(bloc.state, const CategoryState.initial());
    });

    group('LoadCategories', () {
      blocTest<CategoryBloc, CategoryState>(
        'should emit [loading, loaded] when getting categories succeeds',
        build: () {
          when(() => mockGetCategoriesUseCase(any()))
              .thenAnswer((_) async => Right(tCategories));
          return bloc;
        },
        act: (bloc) => bloc.add(const CategoryEvent.loadCategories()),
        expect: () => [
          CategoryState.loading(categories: const []),
          CategoryState.loaded(categories: tCategories),
        ],
        verify: (_) {
          verify(() => mockGetCategoriesUseCase(const NoParams())).called(1);
        },
      );

      blocTest<CategoryBloc, CategoryState>(
        'should emit [loading, error] when getting categories fails',
        build: () {
          when(() => mockGetCategoriesUseCase(any())).thenAnswer(
            (_) async => const Left(Failure.database(
              message: 'Failed to get categories',
              exception: null,
            )),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const CategoryEvent.loadCategories()),
        expect: () => [
          CategoryState.loading(categories: const []),
          const CategoryState.error(
            categories: [],
            failure: Failure.database(
              message: 'Failed to get categories',
              exception: null,
            ),
          ),
        ],
        verify: (_) {
          verify(() => mockGetCategoriesUseCase(const NoParams())).called(1);
        },
      );

      test('should emit error UI effect when getting categories fails', () async {
        // Arrange
        when(() => mockGetCategoriesUseCase(any())).thenAnswer(
          (_) async => const Left(Failure.database(
            message: 'Failed to get categories',
            exception: null,
          )),
        );

        final effects = <CategoryUiEffect>[];
        final subscription = bloc.effectStream.listen(effects.add);

        // Act
        bloc.add(const CategoryEvent.loadCategories());
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(effects.length, 1);
        expect(
          effects.first,
          const CategoryUiEffect.showError('Failed to get categories'),
        );

        await subscription.cancel();
      });
    });

    group('CreateCategory', () {
      final tCategory = Category(
        id: '3',
        name: 'Shopping',
        colorHex: '5733FF',
        createdAt: DateTime(2024, 1, 3),
      );

      blocTest<CategoryBloc, CategoryState>(
        'should emit [loading, loaded] when creation succeeds',
        build: () {
          when(() => mockCreateCategoryUseCase(any()))
              .thenAnswer((_) async => Right(tCategory));
          when(() => mockGetCategoriesUseCase(any()))
              .thenAnswer((_) async => Right([...tCategories, tCategory]));
          return bloc;
        },
        act: (bloc) => bloc.add(CategoryEvent.createCategory(category: tCategory)),
        expect: () => [
          CategoryState.loading(categories: const []),
          CategoryState.loaded(categories: [...tCategories, tCategory]),
        ],
        wait: const Duration(milliseconds: 100),
        verify: (_) {
          verify(() => mockCreateCategoryUseCase(any())).called(1);
        },
      );

      test('should emit success UI effect when creation succeeds', () async {
        // Arrange
        when(() => mockCreateCategoryUseCase(any()))
            .thenAnswer((_) async => Right(tCategory));
        when(() => mockGetCategoriesUseCase(any()))
            .thenAnswer((_) async => Right([...tCategories, tCategory]));

        final effects = <CategoryUiEffect>[];
        final subscription = bloc.effectStream.listen(effects.add);

        // Act
        bloc.add(CategoryEvent.createCategory(category: tCategory));
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(effects.length, 1);
        effects.first.map(
          showError: (_) => fail('Expected showSuccess'),
          showSuccess: (effect) {
            expect(effect.message, contains('Shopping'));
            expect(effect.message, contains('created'));
          },
          confirmDelete: (_) => fail('Expected showSuccess'),
        );

        await subscription.cancel();
      });

      blocTest<CategoryBloc, CategoryState>(
        'should emit [loading, error] when creation fails',
        build: () {
          when(() => mockCreateCategoryUseCase(any())).thenAnswer(
            (_) async => const Left(Failure.validation(
              message: 'Category name cannot be empty',
              field: 'name',
            )),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(CategoryEvent.createCategory(category: tCategory)),
        expect: () => [
          CategoryState.loading(categories: const []),
          const CategoryState.error(
            categories: [],
            failure: Failure.validation(
              message: 'Category name cannot be empty',
              field: 'name',
            ),
          ),
        ],
      );

      test('should emit error UI effect when creation fails', () async {
        // Arrange
        when(() => mockCreateCategoryUseCase(any())).thenAnswer(
          (_) async => const Left(Failure.validation(
            message: 'Category name cannot be empty',
            field: 'name',
          )),
        );

        final effects = <CategoryUiEffect>[];
        final subscription = bloc.effectStream.listen(effects.add);

        // Act
        bloc.add(CategoryEvent.createCategory(category: tCategory));
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(effects.length, 1);
        expect(
          effects.first,
          const CategoryUiEffect.showError('Category name cannot be empty'),
        );

        await subscription.cancel();
      });
    });

    group('UpdateCategory', () {
      final tCategory = Category(
        id: '1',
        name: 'Updated Work',
        colorHex: 'FF5733',
        createdAt: DateTime(2024, 1, 1),
        taskCount: 10,
      );

      blocTest<CategoryBloc, CategoryState>(
        'should emit [loading, loaded] when update succeeds',
        build: () {
          when(() => mockUpdateCategoryUseCase(any()))
              .thenAnswer((_) async => Right(tCategory));
          when(() => mockGetCategoriesUseCase(any()))
              .thenAnswer((_) async => Right([tCategory, tCategories[1]]));
          return bloc;
        },
        act: (bloc) => bloc.add(CategoryEvent.updateCategory(category: tCategory)),
        expect: () => [
          CategoryState.loading(categories: const []),
          CategoryState.loaded(categories: [tCategory, tCategories[1]]),
        ],
        wait: const Duration(milliseconds: 100),
        verify: (_) {
          verify(() => mockUpdateCategoryUseCase(any())).called(1);
        },
      );

      test('should emit success UI effect when update succeeds', () async {
        // Arrange
        when(() => mockUpdateCategoryUseCase(any()))
            .thenAnswer((_) async => Right(tCategory));
        when(() => mockGetCategoriesUseCase(any()))
            .thenAnswer((_) async => Right([tCategory, tCategories[1]]));

        final effects = <CategoryUiEffect>[];
        final subscription = bloc.effectStream.listen(effects.add);

        // Act
        bloc.add(CategoryEvent.updateCategory(category: tCategory));
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(effects.length, 1);
        effects.first.map(
          showError: (_) => fail('Expected showSuccess'),
          showSuccess: (effect) {
            expect(effect.message, contains('Updated Work'));
            expect(effect.message, contains('updated'));
          },
          confirmDelete: (_) => fail('Expected showSuccess'),
        );

        await subscription.cancel();
      });

      blocTest<CategoryBloc, CategoryState>(
        'should emit [loading, error] when update fails',
        build: () {
          when(() => mockUpdateCategoryUseCase(any())).thenAnswer(
            (_) async => const Left(Failure.notFound(
              message: 'Category not found',
            )),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(CategoryEvent.updateCategory(category: tCategory)),
        expect: () => [
          CategoryState.loading(categories: const []),
          const CategoryState.error(
            categories: [],
            failure: Failure.notFound(
              message: 'Category not found',
            ),
          ),
        ],
      );
    });

    group('DeleteCategory', () {
      const tCategoryId = '1';
      const tCategoryName = 'Work';

      test('should emit confirm delete UI effect', () async {
        // Arrange
        final effects = <CategoryUiEffect>[];
        final subscription = bloc.effectStream.listen(effects.add);

        // Act
        bloc.add(const CategoryEvent.deleteCategory(
          categoryId: tCategoryId,
          categoryName: tCategoryName,
        ));
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(effects.length, 1);
        effects.first.map(
          showError: (_) => fail('Expected confirmDelete'),
          showSuccess: (_) => fail('Expected confirmDelete'),
          confirmDelete: (effect) {
            expect(effect.categoryId, tCategoryId);
            expect(effect.categoryName, tCategoryName);
          },
        );

        await subscription.cancel();
      });

      test('onConfirmed callback triggers deleteConfirmed event', () async {
        // Arrange
        when(() => mockDeleteCategoryUseCase(any()))
            .thenAnswer((_) async => const Right(unit));
        when(() => mockGetCategoriesUseCase(any()))
            .thenAnswer((_) async => const Right([]));

        final effects = <CategoryUiEffect>[];
        final subscription = bloc.effectStream.listen(effects.add);

        // Act
        bloc.add(const CategoryEvent.deleteCategory(
          categoryId: tCategoryId,
          categoryName: tCategoryName,
        ));
        await Future.delayed(const Duration(milliseconds: 100));

        // Get the confirm effect and call onConfirmed
        final confirmEffect = effects.first;
        confirmEffect.map(
          showError: (_) => fail('Expected confirmDelete'),
          showSuccess: (_) => fail('Expected confirmDelete'),
          confirmDelete: (effect) {
            effect.onConfirmed();
          },
        );

        await Future.delayed(const Duration(milliseconds: 100));

        // Assert - deletion should have been triggered
        verify(() => mockDeleteCategoryUseCase(any())).called(1);

        await subscription.cancel();
      });
    });

    group('DeleteConfirmed', () {
      const tCategoryId = '1';
      const tCategoryName = 'Work';

      blocTest<CategoryBloc, CategoryState>(
        'should emit [loading, loaded] when deletion succeeds',
        build: () {
          when(() => mockDeleteCategoryUseCase(any()))
              .thenAnswer((_) async => const Right(unit));
          when(() => mockGetCategoriesUseCase(any()))
              .thenAnswer((_) async => Right([tCategories[1]]));
          return bloc;
        },
        act: (bloc) => bloc.add(const CategoryEvent.deleteConfirmed(
          categoryId: tCategoryId,
          categoryName: tCategoryName,
        )),
        expect: () => [
          CategoryState.loading(categories: const []),
          CategoryState.loaded(categories: [tCategories[1]]),
        ],
        wait: const Duration(milliseconds: 100),
        verify: (_) {
          verify(() => mockDeleteCategoryUseCase(any())).called(1);
        },
      );

      test('should emit success UI effect when deletion succeeds', () async {
        // Arrange
        when(() => mockDeleteCategoryUseCase(any()))
            .thenAnswer((_) async => const Right(unit));
        when(() => mockGetCategoriesUseCase(any()))
            .thenAnswer((_) async => Right([tCategories[1]]));

        final effects = <CategoryUiEffect>[];
        final subscription = bloc.effectStream.listen(effects.add);

        // Act
        bloc.add(const CategoryEvent.deleteConfirmed(
          categoryId: tCategoryId,
          categoryName: tCategoryName,
        ));
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(effects.length, 1);
        effects.first.map(
          showError: (_) => fail('Expected showSuccess'),
          showSuccess: (effect) {
            expect(effect.message, contains(tCategoryName));
            expect(effect.message, contains('deleted'));
          },
          confirmDelete: (_) => fail('Expected showSuccess'),
        );

        await subscription.cancel();
      });

      blocTest<CategoryBloc, CategoryState>(
        'should emit [loading, error] when deletion fails',
        build: () {
          when(() => mockDeleteCategoryUseCase(any())).thenAnswer(
            (_) async => const Left(Failure.notFound(
              message: 'Category not found',
            )),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const CategoryEvent.deleteConfirmed(
          categoryId: tCategoryId,
          categoryName: tCategoryName,
        )),
        expect: () => [
          CategoryState.loading(categories: const []),
          const CategoryState.error(
            categories: [],
            failure: Failure.notFound(
              message: 'Category not found',
            ),
          ),
        ],
      );
    });

    group('Failure Messages', () {
      test('should convert database failure to message', () async {
        // Arrange
        when(() => mockGetCategoriesUseCase(any())).thenAnswer(
          (_) async => const Left(Failure.database(
            message: 'Database connection failed',
            exception: null,
          )),
        );

        final effects = <CategoryUiEffect>[];
        final subscription = bloc.effectStream.listen(effects.add);

        // Act
        bloc.add(const CategoryEvent.loadCategories());
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(effects.first, const CategoryUiEffect.showError(
          'Database connection failed',
        ));

        await subscription.cancel();
      });

      test('should convert validation failure to message', () async {
        // Arrange
        when(() => mockGetCategoriesUseCase(any())).thenAnswer(
          (_) async => const Left(Failure.validation(
            message: 'Invalid input',
            field: 'name',
          )),
        );

        final effects = <CategoryUiEffect>[];
        final subscription = bloc.effectStream.listen(effects.add);

        // Act
        bloc.add(const CategoryEvent.loadCategories());
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(effects.first, const CategoryUiEffect.showError(
          'Invalid input',
        ));

        await subscription.cancel();
      });

      test('should convert not found failure to message', () async {
        // Arrange
        when(() => mockGetCategoriesUseCase(any())).thenAnswer(
          (_) async => const Left(Failure.notFound(
            message: 'Category not found',
          )),
        );

        final effects = <CategoryUiEffect>[];
        final subscription = bloc.effectStream.listen(effects.add);

        // Act
        bloc.add(const CategoryEvent.loadCategories());
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(effects.first, const CategoryUiEffect.showError(
          'Category not found',
        ));

        await subscription.cancel();
      });

      test('should convert cache failure to message', () async {
        // Arrange
        when(() => mockGetCategoriesUseCase(any())).thenAnswer(
          (_) async => const Left(Failure.cache(
            message: 'Cache error',
          )),
        );

        final effects = <CategoryUiEffect>[];
        final subscription = bloc.effectStream.listen(effects.add);

        // Act
        bloc.add(const CategoryEvent.loadCategories());
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(effects.first, const CategoryUiEffect.showError(
          'Cache error',
        ));

        await subscription.cancel();
      });

      test('should convert unknown failure to generic message', () async {
        // Arrange
        when(() => mockGetCategoriesUseCase(any())).thenAnswer(
          (_) async => const Left(Failure.unknown(
            message: 'Something went wrong',
            error: null,
          )),
        );

        final effects = <CategoryUiEffect>[];
        final subscription = bloc.effectStream.listen(effects.add);

        // Act
        bloc.add(const CategoryEvent.loadCategories());
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(effects.first, const CategoryUiEffect.showError(
          'An unexpected error occurred',
        ));

        await subscription.cancel();
      });
    });

    group('CategoryStateX Extension', () {
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

      test('isLoading returns true for loading state', () {
        const state = CategoryState.loading();
        expect(state.isLoading, true);
      });

      test('isLoading returns false for non-loading states', () {
        expect(const CategoryState.initial().isLoading, false);
        expect(CategoryState.loaded(categories: tCategories).isLoading, false);
        expect(
          const CategoryState.error(
            failure: Failure.unknown(message: 'Error', error: null),
          ).isLoading,
          false,
        );
      });

      test('isError returns true for error state', () {
        const state = CategoryState.error(
          failure: Failure.unknown(message: 'Error', error: null),
        );
        expect(state.isError, true);
      });

      test('isError returns false for non-error states', () {
        expect(const CategoryState.initial().isError, false);
        expect(const CategoryState.loading().isError, false);
        expect(CategoryState.loaded(categories: tCategories).isError, false);
      });

      test('failure returns failure for error state', () {
        const testFailure = Failure.unknown(message: 'Error', error: null);
        const state = CategoryState.error(failure: testFailure);
        expect(state.failure, testFailure);
      });

      test('failure returns null for non-error states', () {
        expect(const CategoryState.initial().failure, isNull);
        expect(const CategoryState.loading().failure, isNull);
        expect(CategoryState.loaded(categories: tCategories).failure, isNull);
      });

      test('isEmpty returns true when categories are empty', () {
        const state = CategoryState.initial(categories: []);
        expect(state.isEmpty, true);
      });

      test('isEmpty returns false when categories are not empty', () {
        final state = CategoryState.loaded(categories: tCategories);
        expect(state.isEmpty, false);
      });

      test('count returns number of categories', () {
        final state = CategoryState.loaded(categories: tCategories);
        expect(state.count, 2);
      });

      test('count returns 0 for empty categories', () {
        const state = CategoryState.initial(categories: []);
        expect(state.count, 0);
      });
    });
  });
}
