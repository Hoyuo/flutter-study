import 'package:auth/domain/entities/user.dart';
import 'package:auth/domain/repositories/auth_repository.dart';
import 'package:auth/domain/usecases/sign_up_usecase.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SignUpUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = SignUpUseCase(mockRepository);
  });

  group('SignUpUseCase', () {
    const testEmail = 'newuser@test.com';
    const testPassword = 'password123';
    const testDisplayName = 'New User';
    final testUser = User(
      id: '1',
      email: testEmail,
      displayName: testDisplayName,
      createdAt: DateTime(2024, 1, 1),
    );

    test('성공 시 User 반환', () async {
      // arrange
      when(() => mockRepository.signUp(
            email: testEmail,
            password: testPassword,
            displayName: testDisplayName,
          )).thenAnswer((_) async => Right(testUser));

      // act
      final result = await useCase(
        SignUpParams(
          email: testEmail,
          password: testPassword,
          displayName: testDisplayName,
        ),
      );

      // assert
      expect(result, Right(testUser));
      verify(() => mockRepository.signUp(
            email: testEmail,
            password: testPassword,
            displayName: testDisplayName,
          )).called(1);
    });

    test('displayName 없이도 성공', () async {
      // arrange
      final userWithoutDisplayName = User(
        id: '1',
        email: testEmail,
        createdAt: DateTime(2024, 1, 1),
      );
      when(() => mockRepository.signUp(
            email: testEmail,
            password: testPassword,
            displayName: null,
          )).thenAnswer((_) async => Right(userWithoutDisplayName));

      // act
      final result = await useCase(
        SignUpParams(
          email: testEmail,
          password: testPassword,
        ),
      );

      // assert
      expect(result, Right(userWithoutDisplayName));
      verify(() => mockRepository.signUp(
            email: testEmail,
            password: testPassword,
            displayName: null,
          )).called(1);
    });

    test('이미 존재하는 이메일 시 AuthFailure 반환', () async {
      // arrange
      const failure = Failure.auth(message: '이미 존재하는 이메일입니다');
      when(() => mockRepository.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
            displayName: any(named: 'displayName'),
          )).thenAnswer((_) async => const Left(failure));

      // act
      final result = await useCase(
        SignUpParams(
          email: testEmail,
          password: testPassword,
        ),
      );

      // assert
      expect(result, const Left(failure));
    });

    test('약한 비밀번호 시 AuthFailure 반환', () async {
      // arrange
      const failure = Failure.auth(message: '비밀번호가 너무 약합니다');
      when(() => mockRepository.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
            displayName: any(named: 'displayName'),
          )).thenAnswer((_) async => const Left(failure));

      // act
      final result = await useCase(
        SignUpParams(
          email: testEmail,
          password: '123',
        ),
      );

      // assert
      expect(result, const Left(failure));
    });
  });
}
