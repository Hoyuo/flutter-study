import 'package:core/core.dart';
import 'package:diary/domain/entities/diary_entry.dart';
import 'package:diary/domain/repositories/diary_repository.dart';
import 'package:diary/domain/usecases/update_diary_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockDiaryRepository extends Mock implements DiaryRepository {}

void main() {
  late UpdateDiaryUseCase useCase;
  late MockDiaryRepository mockRepository;

  setUpAll(() {
    // mocktail registerFallbackValue
    registerFallbackValue(
      DiaryEntry(
        id: '',
        userId: '',
        title: '',
        content: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  });

  setUp(() {
    mockRepository = MockDiaryRepository();
    useCase = UpdateDiaryUseCase(mockRepository);
  });

  group('UpdateDiaryUseCase', () {
    final originalEntry = DiaryEntry(
      id: '1',
      userId: 'user1',
      title: '원본 제목',
      content: '원본 내용',
      createdAt: DateTime(2024, 1, 1, 10, 0),
      updatedAt: DateTime(2024, 1, 1, 10, 0),
    );

    final updatedEntry = DiaryEntry(
      id: '1',
      userId: 'user1',
      title: '수정된 제목',
      content: '수정된 내용',
      photoUrls: ['https://example.com/photo.jpg'],
      createdAt: DateTime(2024, 1, 1, 10, 0),
      updatedAt: DateTime(2024, 1, 1, 11, 0),
    );

    test('성공 시 수정된 DiaryEntry 반환', () async {
      // arrange
      when(() => mockRepository.updateDiary(any()))
          .thenAnswer((_) async => Right(updatedEntry));

      // act
      final result = await useCase(updatedEntry);

      // assert
      expect(result, Right(updatedEntry));
      verify(() => mockRepository.updateDiary(updatedEntry)).called(1);
    });

    test('제목만 수정해도 성공', () async {
      // arrange
      final titleOnlyUpdate = originalEntry.copyWith(
        title: '새로운 제목',
        updatedAt: DateTime(2024, 1, 1, 11, 0),
      );
      when(() => mockRepository.updateDiary(any()))
          .thenAnswer((_) async => Right(titleOnlyUpdate));

      // act
      final result = await useCase(titleOnlyUpdate);

      // assert
      expect(result, Right(titleOnlyUpdate));
    });

    test('내용만 수정해도 성공', () async {
      // arrange
      final contentOnlyUpdate = originalEntry.copyWith(
        content: '새로운 내용',
        updatedAt: DateTime(2024, 1, 1, 11, 0),
      );
      when(() => mockRepository.updateDiary(any()))
          .thenAnswer((_) async => Right(contentOnlyUpdate));

      // act
      final result = await useCase(contentOnlyUpdate);

      // assert
      expect(result, Right(contentOnlyUpdate));
    });

    test('존재하지 않는 다이어리 수정 시 ServerFailure 반환', () async {
      // arrange
      const failure = Failure.server(
        message: '다이어리를 찾을 수 없습니다',
        statusCode: 404,
      );
      when(() => mockRepository.updateDiary(any()))
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await useCase(updatedEntry);

      // assert
      expect(result, const Left(failure));
    });

    test('권한 에러 시 AuthFailure 반환', () async {
      // arrange
      const failure = Failure.auth(message: '수정 권한이 없습니다');
      when(() => mockRepository.updateDiary(any()))
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await useCase(updatedEntry);

      // assert
      expect(result, const Left(failure));
    });

    test('네트워크 에러 시 NetworkFailure 반환', () async {
      // arrange
      const failure = Failure.network(message: '네트워크 연결 실패');
      when(() => mockRepository.updateDiary(any()))
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await useCase(updatedEntry);

      // assert
      expect(result, const Left(failure));
    });
  });
}
