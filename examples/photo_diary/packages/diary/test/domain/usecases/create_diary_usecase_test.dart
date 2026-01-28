import 'package:core/core.dart';
import 'package:diary/domain/entities/diary_entry.dart';
import 'package:diary/domain/entities/tag.dart';
import 'package:diary/domain/repositories/diary_repository.dart';
import 'package:diary/domain/usecases/create_diary_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockDiaryRepository extends Mock implements DiaryRepository {}

void main() {
  late CreateDiaryUseCase useCase;
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
    useCase = CreateDiaryUseCase(mockRepository);
  });

  group('CreateDiaryUseCase', () {
    final testEntry = DiaryEntry(
      id: '1',
      userId: 'user1',
      title: '오늘의 일기',
      content: '오늘은 좋은 날이었다.',
      photoUrls: ['https://example.com/photo1.jpg'],
      tags: [
        const Tag(
          id: 'tag1',
          name: '일상',
          colorHex: '#FF5733',
          userId: 'user1',
        ),
      ],
      weather: const WeatherInfo(
        condition: 'Clear',
        temperature: 25.0,
        iconUrl: 'https://example.com/icon.png',
        humidity: 60.0,
      ),
      createdAt: DateTime(2024, 1, 1, 10, 0),
      updatedAt: DateTime(2024, 1, 1, 10, 0),
      syncStatus: SyncStatus.synced,
    );

    test('성공 시 생성된 DiaryEntry 반환', () async {
      // arrange
      when(() => mockRepository.createDiary(any()))
          .thenAnswer((_) async => Right(testEntry));

      // act
      final result = await useCase(testEntry);

      // assert
      expect(result, Right(testEntry));
      verify(() => mockRepository.createDiary(testEntry)).called(1);
    });

    test('서버 에러 시 ServerFailure 반환', () async {
      // arrange
      const failure = Failure.server(
        message: '서버에 다이어리를 생성할 수 없습니다',
        statusCode: 500,
      );
      when(() => mockRepository.createDiary(any()))
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await useCase(testEntry);

      // assert
      expect(result, const Left(failure));
    });

    test('네트워크 에러 시 NetworkFailure 반환', () async {
      // arrange
      const failure = Failure.network(message: '네트워크 연결 실패');
      when(() => mockRepository.createDiary(any()))
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await useCase(testEntry);

      // assert
      expect(result, const Left(failure));
    });

    test('권한 에러 시 AuthFailure 반환', () async {
      // arrange
      const failure = Failure.auth(message: '권한이 없습니다');
      when(() => mockRepository.createDiary(any()))
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await useCase(testEntry);

      // assert
      expect(result, const Left(failure));
    });
  });
}
