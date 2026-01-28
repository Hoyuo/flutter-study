import 'package:auth/domain/entities/user.dart';
import 'package:auth/domain/repositories/auth_repository.dart';
import 'package:auth/domain/usecases/sign_in_with_email_usecase.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SignInWithEmailUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = SignInWithEmailUseCase(mockRepository);
  });

  group('SignInWithEmailUseCase', () {
    const testEmail = 'test@test.com';
    const testPassword = 'password123';
    final testUser = User(
      id: '1',
      email: testEmail,
      displayName: 'Test User',
      createdAt: DateTime(2024, 1, 1),
    );

    test('성공 시 User 반환', () async {
      // arrange
      when(() => mockRepository.signInWithEmail(
            email: testEmail,
            password: testPassword,
          )).thenAnswer((_) async => Right(testUser));

      // act
      final result = await useCase(
        SignInParams(
          email: testEmail,
          password: testPassword,
        ),
      );

      // assert
      expect(result, Right(testUser));
      verify(() => mockRepository.signInWithEmail(
            email: testEmail,
            password: testPassword,
          )).called(1);
    });

    test('실패 시 Failure 반환', () async {
      // arrange
      const failure = Failure.auth(message: '잘못된 비밀번호');
      when(() => mockRepository.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => const Left(failure));

      // act
      final result = await useCase(
        SignInParams(
          email: testEmail,
          password: 'wrong',
        ),
      );

      // assert
      expect(result, const Left(failure));
    });

    test('네트워크 에러 시 NetworkFailure 반환', () async {
      // arrange
      const failure = Failure.network(message: '네트워크 연결 실패');
      when(() => mockRepository.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => const Left(failure));

      // act
      final result = await useCase(
        SignInParams(
          email: testEmail,
          password: testPassword,
        ),
      );

      // assert
      expect(result, const Left(failure));
    });
  });
}
