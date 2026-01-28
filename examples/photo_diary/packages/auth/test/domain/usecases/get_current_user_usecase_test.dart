import 'package:auth/domain/entities/user.dart';
import 'package:auth/domain/repositories/auth_repository.dart';
import 'package:auth/domain/usecases/get_current_user_usecase.dart';
import 'package:core/core.dart';
import 'package:core/types/usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late GetCurrentUserUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = GetCurrentUserUseCase(mockRepository);
  });

  group('GetCurrentUserUseCase', () {
    final testUser = User(
      id: '1',
      email: 'test@test.com',
      displayName: 'Test User',
      photoUrl: 'https://example.com/photo.jpg',
      createdAt: DateTime(2024, 1, 1),
    );

    test('로그인된 사용자가 있을 때 User 반환', () async {
      // arrange
      when(() => mockRepository.getCurrentUser())
          .thenAnswer((_) async => Right(testUser));

      // act
      final result = await useCase(const NoParams());

      // assert
      expect(result, Right(testUser));
      verify(() => mockRepository.getCurrentUser()).called(1);
    });

    test('로그인된 사용자가 없을 때 null 반환', () async {
      // arrange
      when(() => mockRepository.getCurrentUser())
          .thenAnswer((_) async => const Right(null));

      // act
      final result = await useCase(const NoParams());

      // assert
      expect(result, const Right(null));
      verify(() => mockRepository.getCurrentUser()).called(1);
    });

    test('에러 시 Failure 반환', () async {
      // arrange
      const failure = Failure.auth(message: '사용자 정보 조회 실패');
      when(() => mockRepository.getCurrentUser())
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await useCase(const NoParams());

      // assert
      expect(result, const Left(failure));
    });

    test('캐시 에러 시 CacheFailure 반환', () async {
      // arrange
      const failure = Failure.cache(message: '캐시된 사용자 정보 읽기 실패');
      when(() => mockRepository.getCurrentUser())
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await useCase(const NoParams());

      // assert
      expect(result, const Left(failure));
    });
  });
}
