import 'package:core/core.dart';
import 'package:diary/domain/entities/diary_entry.dart';
import 'package:diary/domain/repositories/diary_repository.dart';
import 'package:diary/domain/usecases/get_diaries_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockDiaryRepository extends Mock implements DiaryRepository {}

void main() {
  late GetDiariesUseCase useCase;
  late MockDiaryRepository mockRepository;

  setUp(() {
    mockRepository = MockDiaryRepository();
    useCase = GetDiariesUseCase(mockRepository);
  });

  group('GetDiariesUseCase', () {
    final testEntries = [
      DiaryEntry(
        id: '1',
        userId: 'user1',
        title: '첫 번째 일기',
        content: '첫 번째 내용',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ),
      DiaryEntry(
        id: '2',
        userId: 'user1',
        title: '두 번째 일기',
        content: '두 번째 내용',
        createdAt: DateTime(2024, 1, 2),
        updatedAt: DateTime(2024, 1, 2),
      ),
    ];

    test('성공 시 DiaryEntry 리스트 반환', () async {
      // arrange
      const params = GetDiariesParams(limit: 20);
      when(() => mockRepository.getDiaries(
            limit: any(named: 'limit'),
            lastEntryId: any(named: 'lastEntryId'),
          )).thenAnswer((_) async => Right(testEntries));

      // act
      final result = await useCase(params);

      // assert
      expect(result, Right(testEntries));
      verify(() => mockRepository.getDiaries(
            limit: 20,
            lastEntryId: null,
          )).called(1);
    });

    test('페이지네이션과 함께 성공', () async {
      // arrange
      const params = GetDiariesParams(
        limit: 10,
        lastEntryId: '2',
      );
      final paginatedEntries = [testEntries.first];
      when(() => mockRepository.getDiaries(
            limit: any(named: 'limit'),
            lastEntryId: any(named: 'lastEntryId'),
          )).thenAnswer((_) async => Right(paginatedEntries));

      // act
      final result = await useCase(params);

      // assert
      expect(result, Right(paginatedEntries));
      verify(() => mockRepository.getDiaries(
            limit: 10,
            lastEntryId: '2',
          )).called(1);
    });

    test('빈 리스트 반환 시 성공', () async {
      // arrange
      const params = GetDiariesParams();
      when(() => mockRepository.getDiaries(
            limit: any(named: 'limit'),
            lastEntryId: any(named: 'lastEntryId'),
          )).thenAnswer((_) async => const Right([]));

      // act
      final result = await useCase(params);

      // assert
      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Should be Right'),
        (list) => expect(list, isEmpty),
      );
    });

    test('네트워크 에러 시 NetworkFailure 반환', () async {
      // arrange
      const params = GetDiariesParams();
      const failure = Failure.network(message: '네트워크 연결 실패');
      when(() => mockRepository.getDiaries(
            limit: any(named: 'limit'),
            lastEntryId: any(named: 'lastEntryId'),
          )).thenAnswer((_) async => const Left(failure));

      // act
      final result = await useCase(params);

      // assert
      expect(result, const Left(failure));
    });

    test('캐시 에러 시 CacheFailure 반환', () async {
      // arrange
      const params = GetDiariesParams();
      const failure = Failure.cache(message: '캐시 읽기 실패');
      when(() => mockRepository.getDiaries(
            limit: any(named: 'limit'),
            lastEntryId: any(named: 'lastEntryId'),
          )).thenAnswer((_) async => const Left(failure));

      // act
      final result = await useCase(params);

      // assert
      expect(result, const Left(failure));
    });
  });
}
