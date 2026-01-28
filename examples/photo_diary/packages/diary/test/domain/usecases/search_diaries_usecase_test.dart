import 'package:core/core.dart';
import 'package:diary/domain/entities/diary_entry.dart';
import 'package:diary/domain/repositories/diary_repository.dart';
import 'package:diary/domain/usecases/search_diaries_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockDiaryRepository extends Mock implements DiaryRepository {}

void main() {
  late SearchDiariesUseCase useCase;
  late MockDiaryRepository mockRepository;

  setUp(() {
    mockRepository = MockDiaryRepository();
    useCase = SearchDiariesUseCase(mockRepository);
  });

  group('SearchDiariesUseCase', () {
    final matchingEntries = [
      DiaryEntry(
        id: '1',
        userId: 'user1',
        title: '맑은 날씨의 하루',
        content: '오늘은 날씨가 맑아서 좋았다',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      ),
      DiaryEntry(
        id: '3',
        userId: 'user1',
        title: '봄날의 산책',
        content: '맑은 봄 날씨에 공원을 산책했다',
        createdAt: DateTime(2024, 1, 3),
        updatedAt: DateTime(2024, 1, 3),
      ),
    ];

    test('검색어와 매칭되는 다이어리 반환', () async {
      // arrange
      const params = SearchDiariesParams(query: '맑은');
      when(() => mockRepository.searchDiaries(
            query: any(named: 'query'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => Right(matchingEntries));

      // act
      final result = await useCase(params);

      // assert
      expect(result, Right(matchingEntries));
      verify(() => mockRepository.searchDiaries(
            query: '맑은',
            limit: 20,
          )).called(1);
    });

    test('커스텀 limit과 함께 검색 성공', () async {
      // arrange
      const params = SearchDiariesParams(
        query: '날씨',
        limit: 10,
      );
      when(() => mockRepository.searchDiaries(
            query: any(named: 'query'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => Right(matchingEntries));

      // act
      final result = await useCase(params);

      // assert
      expect(result, Right(matchingEntries));
      verify(() => mockRepository.searchDiaries(
            query: '날씨',
            limit: 10,
          )).called(1);
    });

    test('매칭되는 결과가 없으면 빈 리스트 반환', () async {
      // arrange
      const params = SearchDiariesParams(query: '존재하지않는검색어');
      when(() => mockRepository.searchDiaries(
            query: any(named: 'query'),
            limit: any(named: 'limit'),
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

    test('빈 검색어로 검색하면 모든 다이어리 반환', () async {
      // arrange
      const params = SearchDiariesParams(query: '');
      final allEntries = [
        ...matchingEntries,
        DiaryEntry(
          id: '2',
          userId: 'user1',
          title: '다른 일기',
          content: '다른 내용',
          createdAt: DateTime(2024, 1, 2),
          updatedAt: DateTime(2024, 1, 2),
        ),
      ];
      when(() => mockRepository.searchDiaries(
            query: any(named: 'query'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => Right(allEntries));

      // act
      final result = await useCase(params);

      // assert
      expect(result, Right(allEntries));
    });

    test('네트워크 에러 시 NetworkFailure 반환', () async {
      // arrange
      const params = SearchDiariesParams(query: '검색어');
      const failure = Failure.network(message: '네트워크 연결 실패');
      when(() => mockRepository.searchDiaries(
            query: any(named: 'query'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => const Left(failure));

      // act
      final result = await useCase(params);

      // assert
      expect(result, const Left(failure));
    });

    test('서버 에러 시 ServerFailure 반환', () async {
      // arrange
      const params = SearchDiariesParams(query: '검색어');
      const failure = Failure.server(
        message: '검색 중 오류 발생',
        statusCode: 500,
      );
      when(() => mockRepository.searchDiaries(
            query: any(named: 'query'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => const Left(failure));

      // act
      final result = await useCase(params);

      // assert
      expect(result, const Left(failure));
    });
  });
}
