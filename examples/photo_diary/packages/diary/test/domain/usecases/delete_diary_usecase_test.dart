import 'package:core/core.dart';
import 'package:diary/domain/repositories/diary_repository.dart';
import 'package:diary/domain/usecases/delete_diary_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockDiaryRepository extends Mock implements DiaryRepository {}

void main() {
  late DeleteDiaryUseCase useCase;
  late MockDiaryRepository mockRepository;

  setUp(() {
    mockRepository = MockDiaryRepository();
    useCase = DeleteDiaryUseCase(mockRepository);
  });

  group('DeleteDiaryUseCase', () {
    const testId = 'diary-1';

    test('성공 시 Unit 반환', () async {
      // arrange
      when(() => mockRepository.deleteDiary(any()))
          .thenAnswer((_) async => right(unit));

      // act
      final result = await useCase(testId);

      // assert
      expect(result, right(unit));
      verify(() => mockRepository.deleteDiary(testId)).called(1);
    });

    test('존재하지 않는 다이어리 삭제 시 ServerFailure 반환', () async {
      // arrange
      const failure = Failure.server(
        message: '다이어리를 찾을 수 없습니다',
        statusCode: 404,
      );
      when(() => mockRepository.deleteDiary(any()))
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await useCase(testId);

      // assert
      expect(result, const Left(failure));
    });

    test('권한 에러 시 AuthFailure 반환', () async {
      // arrange
      const failure = Failure.auth(message: '삭제 권한이 없습니다');
      when(() => mockRepository.deleteDiary(any()))
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await useCase(testId);

      // assert
      expect(result, const Left(failure));
    });

    test('네트워크 에러 시 NetworkFailure 반환', () async {
      // arrange
      const failure = Failure.network(message: '네트워크 연결 실패');
      when(() => mockRepository.deleteDiary(any()))
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await useCase(testId);

      // assert
      expect(result, const Left(failure));
    });

    test('서버 에러 시 ServerFailure 반환', () async {
      // arrange
      const failure = Failure.server(
        message: '서버 내부 오류',
        statusCode: 500,
      );
      when(() => mockRepository.deleteDiary(any()))
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await useCase(testId);

      // assert
      expect(result, const Left(failure));
    });
  });
}
