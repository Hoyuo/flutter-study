import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' hide Unit;
import 'package:core/error/failure.dart';
import 'package:core/types/usecase.dart';

// Test implementation of UseCase
class TestUseCase extends UseCase<String, TestParams> {
  final bool shouldSucceed;

  TestUseCase({this.shouldSucceed = true});

  @override
  Future<Either<Failure, String>> call(TestParams params) async {
    if (shouldSucceed) {
      return right('Success: ${params.value}');
    } else {
      return left(const Failure.unknown(message: 'Test failure'));
    }
  }
}

class TestParams {
  final String value;

  const TestParams(this.value);
}

// Test implementation with NoParams
class NoParamsUseCase extends UseCase<int, NoParams> {
  @override
  Future<Either<Failure, int>> call(NoParams params) async {
    return right(42);
  }
}

void main() {
  group('UseCase', () {
    test('should execute successfully with parameters', () async {
      final useCase = TestUseCase();
      final params = const TestParams('test');

      final result = await useCase.call(params);

      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not fail'),
        (value) => expect(value, 'Success: test'),
      );
    });

    test('should return failure when operation fails', () async {
      final useCase = TestUseCase(shouldSucceed: false);
      final params = const TestParams('test');

      final result = await useCase.call(params);

      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<UnknownFailure>());
          failure.when(
            database: (_, __) => fail('Should not be database'),
            validation: (_, __) => fail('Should not be validation'),
            notFound: (_, __) => fail('Should not be notFound'),
            cache: (_, __) => fail('Should not be cache'),
            unknown: (message, error) {
              expect(message, 'Test failure');
            },
          );
        },
        (value) => fail('Should not succeed'),
      );
    });

    test('should work with different parameter types', () async {
      final useCase = TestUseCase();
      final params1 = const TestParams('first');
      final params2 = const TestParams('second');

      final result1 = await useCase.call(params1);
      final result2 = await useCase.call(params2);

      result1.fold(
        (failure) => fail('Should not fail'),
        (value) => expect(value, 'Success: first'),
      );
      result2.fold(
        (failure) => fail('Should not fail'),
        (value) => expect(value, 'Success: second'),
      );
    });
  });

  group('NoParams', () {
    test('should create NoParams instance', () {
      const params = NoParams();
      expect(params, isA<NoParams>());
    });

    test('should work with use cases that require no parameters', () async {
      final useCaseInstance = NoParamsUseCase();
      const params = NoParams();

      final result = await useCaseInstance.call(params);

      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not fail'),
        (value) => expect(value, 42),
      );
    });

    test('should support multiple instances', () {
      const params1 = NoParams();
      const params2 = NoParams();

      // All NoParams instances should be usable
      expect(params1, isA<NoParams>());
      expect(params2, isA<NoParams>());
    });
  });


  group('Integration tests', () {
    test('should chain multiple use cases', () async {
      final testUseCase = TestUseCase();
      final noParamsUseCase = NoParamsUseCase();

      // Execute first use case
      final result1 = await noParamsUseCase.call(const NoParams());

      await result1.fold(
        (failure) => fail('Should not fail'),
        (value) async {
          expect(value, 42);

          // Execute second use case with result from first
          final result2 = await testUseCase.call(TestParams('value: $value'));
          result2.fold(
            (failure) => fail('Should not fail'),
            (message) => expect(message, 'Success: value: 42'),
          );
        },
      );
    });

    test('should handle mixed success and failure scenarios', () async {
      final successUseCase = TestUseCase(shouldSucceed: true);
      final failureUseCase = TestUseCase(shouldSucceed: false);

      final result1 = await successUseCase.call(const TestParams('test1'));
      final result2 = await failureUseCase.call(const TestParams('test2'));

      expect(result1.isRight(), true);
      expect(result2.isLeft(), true);
    });

    test('should handle NoParams use case in chain', () async {
      final noParamsUseCase = NoParamsUseCase();

      final result = await noParamsUseCase.call(const NoParams());

      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not fail'),
        (value) => expect(value, 42),
      );
    });
  });
}
