import 'package:auth/domain/repositories/auth_repository.dart';
import 'package:auth/domain/usecases/sign_out_usecase.dart';
import 'package:core/core.dart';
import 'package:core/types/usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SignOutUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = SignOutUseCase(mockRepository);
  });

  group('SignOutUseCase', () {
    test('성공 시 Unit 반환', () async {
      // arrange
      when(() => mockRepository.signOut()).thenAnswer((_) async => right(unit));

      // act
      final result = await useCase(const NoParams());

      // assert
      expect(result, right(unit));
      verify(() => mockRepository.signOut()).called(1);
    });

    test('실패 시 Failure 반환', () async {
      // arrange
      const failure = Failure.auth(message: '로그아웃 실패');
      when(() => mockRepository.signOut())
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await useCase(const NoParams());

      // assert
      expect(result, const Left(failure));
    });

    test('네트워크 에러 시 NetworkFailure 반환', () async {
      // arrange
      const failure = Failure.network(message: '네트워크 연결 실패');
      when(() => mockRepository.signOut())
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await useCase(const NoParams());

      // assert
      expect(result, const Left(failure));
    });
  });
}
