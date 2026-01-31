import 'package:core/core.dart';
import 'package:diary/domain/entities/tag.dart';
import 'package:diary/domain/repositories/tag_repository.dart';
import 'package:diary/domain/usecases/create_tag_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockTagRepository extends Mock implements TagRepository {}

void main() {
  late CreateTagUseCase useCase;
  late MockTagRepository mockRepository;

  setUpAll(() {
    // mocktail registerFallbackValue
    registerFallbackValue(
      const Tag(
        id: '',
        name: '',
        colorHex: '',
        userId: '',
      ),
    );
  });

  setUp(() {
    mockRepository = MockTagRepository();
    useCase = CreateTagUseCase(mockRepository);
  });

  group('CreateTagUseCase', () {
    const testTag = Tag(
      id: 'tag1',
      name: '여행',
      colorHex: '#FF5733',
      userId: 'user1',
    );

    test('성공 시 생성된 Tag 반환', () async {
      // arrange
      when(() => mockRepository.createTag(any()))
          .thenAnswer((_) async => const Right(testTag));

      // act
      final result = await useCase(testTag);

      // assert
      expect(result, const Right(testTag));
      verify(() => mockRepository.createTag(testTag)).called(1);
    });

    test('서버 에러 시 ServerFailure 반환', () async {
      // arrange
      const failure = Failure.server(
        message: '태그를 생성할 수 없습니다',
        statusCode: 500,
      );
      when(() => mockRepository.createTag(any()))
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await useCase(testTag);

      // assert
      expect(result, const Left(failure));
    });

    test('네트워크 에러 시 NetworkFailure 반환', () async {
      // arrange
      const failure = Failure.network(message: '네트워크 연결 실패');
      when(() => mockRepository.createTag(any()))
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await useCase(testTag);

      // assert
      expect(result, const Left(failure));
    });

    test('권한 에러 시 AuthFailure 반환', () async {
      // arrange
      const failure = Failure.auth(message: '권한이 없습니다');
      when(() => mockRepository.createTag(any()))
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await useCase(testTag);

      // assert
      expect(result, const Left(failure));
    });
  });
}
