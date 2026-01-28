import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:diary/domain/entities/entities.dart';
import 'package:diary/domain/usecases/usecases.dart';
import 'package:diary/presentation/bloc/diary_bloc.dart';
import 'package:diary/presentation/bloc/diary_event.dart';
import 'package:diary/presentation/bloc/diary_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

// Mock 클래스 정의
class MockGetDiariesUseCase extends Mock implements GetDiariesUseCase {}

class MockGetDiaryByIdUseCase extends Mock implements GetDiaryByIdUseCase {}

class MockCreateDiaryUseCase extends Mock implements CreateDiaryUseCase {}

class MockUpdateDiaryUseCase extends Mock implements UpdateDiaryUseCase {}

class MockDeleteDiaryUseCase extends Mock implements DeleteDiaryUseCase {}

class MockSearchDiariesUseCase extends Mock implements SearchDiariesUseCase {}

// Fake 클래스 (mocktail에서 Any matcher 사용 시 필요)
class FakeGetDiariesParams extends Fake implements GetDiariesParams {}

class FakeDiaryEntry extends Fake implements DiaryEntry {}

class FakeSearchDiariesParams extends Fake implements SearchDiariesParams {}

void main() {
  late DiaryBloc bloc;
  late MockGetDiariesUseCase mockGetDiaries;
  late MockGetDiaryByIdUseCase mockGetDiaryById;
  late MockCreateDiaryUseCase mockCreateDiary;
  late MockUpdateDiaryUseCase mockUpdateDiary;
  late MockDeleteDiaryUseCase mockDeleteDiary;
  late MockSearchDiariesUseCase mockSearchDiaries;

  // 테스트용 데이터
  final testTag1 = Tag(
    id: 'tag-1',
    name: '여행',
    colorHex: '#FF5733',
    userId: 'user-1',
  );

  final testTag2 = Tag(
    id: 'tag-2',
    name: '일상',
    colorHex: '#33C4FF',
    userId: 'user-1',
  );

  final testEntry1 = DiaryEntry(
    id: 'entry-1',
    userId: 'user-1',
    title: '첫 번째 일기',
    content: '오늘은 날씨가 좋았다.',
    photoUrls: ['https://example.com/photo1.jpg'],
    tags: [testTag1],
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );

  final testEntry2 = DiaryEntry(
    id: 'entry-2',
    userId: 'user-1',
    title: '두 번째 일기',
    content: '오늘은 비가 왔다.',
    photoUrls: [],
    tags: [testTag2],
    createdAt: DateTime(2024, 1, 2),
    updatedAt: DateTime(2024, 1, 2),
  );

  setUpAll(() {
    // Fake 클래스 등록
    registerFallbackValue(FakeGetDiariesParams());
    registerFallbackValue(FakeDiaryEntry());
    registerFallbackValue(FakeSearchDiariesParams());
  });

  setUp(() {
    mockGetDiaries = MockGetDiariesUseCase();
    mockGetDiaryById = MockGetDiaryByIdUseCase();
    mockCreateDiary = MockCreateDiaryUseCase();
    mockUpdateDiary = MockUpdateDiaryUseCase();
    mockDeleteDiary = MockDeleteDiaryUseCase();
    mockSearchDiaries = MockSearchDiariesUseCase();

    bloc = DiaryBloc(
      getDiariesUseCase: mockGetDiaries,
      getDiaryByIdUseCase: mockGetDiaryById,
      createDiaryUseCase: mockCreateDiary,
      updateDiaryUseCase: mockUpdateDiary,
      deleteDiaryUseCase: mockDeleteDiary,
      searchDiariesUseCase: mockSearchDiaries,
    );
  });

  tearDown(() => bloc.close());

  group('DiaryBloc', () {
    test('초기 상태 확인', () {
      expect(bloc.state.entries, isEmpty);
      expect(bloc.state.isLoading, isFalse);
      expect(bloc.state.hasReachedEnd, isFalse);
      expect(bloc.state.currentPage, 1);
      expect(bloc.state.failure, isNull);
    });

    group('일기 목록 로드 (LoadDiaryEntries)', () {
      blocTest<DiaryBloc, DiaryState>(
        '일기 목록 로드 성공',
        build: () {
          when(() => mockGetDiaries(any())).thenAnswer(
            (_) async => Right([testEntry1, testEntry2]),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const DiaryEvent.loadEntries()),
        expect: () => [
          // 로딩 시작
          isA<DiaryState>()
              .having((s) => s.isLoading, 'isLoading', true)
              .having((s) => s.failure, 'failure', isNull),
          // 데이터 로드 완료 (아직 isLoading은 true)
          isA<DiaryState>()
              .having((s) => s.entries.length, 'entries length', 2)
              .having((s) => s.entries[0], 'first entry', testEntry1)
              .having((s) => s.entries[1], 'second entry', testEntry2),
          // 로딩 종료
          isA<DiaryState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.entries.length, 'entries length', 2),
        ],
        verify: (_) {
          verify(() => mockGetDiaries(any())).called(1);
        },
      );

      blocTest<DiaryBloc, DiaryState>(
        '일기 목록 로드 실패 시 failure 설정',
        build: () {
          when(() => mockGetDiaries(any())).thenAnswer(
            (_) async => const Left(Failure.network(message: '네트워크 오류')),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const DiaryEvent.loadEntries()),
        expect: () => [
          // 로딩 시작
          isA<DiaryState>().having((s) => s.isLoading, 'isLoading', true),
          // 실패 설정 (아직 isLoading은 true)
          isA<DiaryState>()
              .having((s) => s.failure, 'failure', isNotNull)
              .having((s) => s.failure?.message, 'failure message', '네트워크 오류'),
          // 로딩 종료
          isA<DiaryState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.failure, 'failure', isNotNull),
        ],
      );
    });

    group('특정 일기 로드 (LoadDiaryEntry)', () {
      blocTest<DiaryBloc, DiaryState>(
        '특정 일기 로드 성공',
        build: () {
          when(() => mockGetDiaryById(any())).thenAnswer(
            (_) async => Right(testEntry1),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const DiaryEvent.loadEntry('entry-1')),
        expect: () => [
          // 로딩 시작
          isA<DiaryState>().having((s) => s.isLoading, 'isLoading', true),
          // 로드 완료
          isA<DiaryState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.selectedEntry, 'selectedEntry', testEntry1),
        ],
        verify: (_) {
          verify(() => mockGetDiaryById('entry-1')).called(1);
        },
      );
    });

    group('일기 생성 (CreateDiaryEntry)', () {
      blocTest<DiaryBloc, DiaryState>(
        '일기 생성 성공 시 목록 맨 앞에 추가',
        build: () {
          when(() => mockCreateDiary(any())).thenAnswer(
            (_) async => Right(testEntry1),
          );
          return bloc;
        },
        seed: () => DiaryState(entries: [testEntry2]),
        act: (bloc) => bloc.add(DiaryEvent.createEntry(testEntry1)),
        expect: () => [
          // 로딩 시작
          isA<DiaryState>().having((s) => s.isLoading, 'isLoading', true),
          // 생성 완료 - 맨 앞에 추가
          isA<DiaryState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.entries.length, 'entries length', 2)
              .having((s) => s.entries.first, 'first entry', testEntry1)
              .having((s) => s.entries.last, 'last entry', testEntry2),
        ],
        verify: (_) {
          verify(() => mockCreateDiary(testEntry1)).called(1);
        },
      );

      blocTest<DiaryBloc, DiaryState>(
        '일기 생성 실패',
        build: () {
          when(() => mockCreateDiary(any())).thenAnswer(
            (_) async => const Left(Failure.server(message: '서버 오류')),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(DiaryEvent.createEntry(testEntry1)),
        expect: () => [
          // 로딩 시작
          isA<DiaryState>().having((s) => s.isLoading, 'isLoading', true),
          // 생성 실패
          isA<DiaryState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.failure, 'failure', isNotNull)
              .having((s) => s.entries, 'entries', isEmpty),
        ],
      );
    });

    group('일기 수정 (UpdateDiaryEntry)', () {
      final updatedEntry = testEntry1.copyWith(
        title: '수정된 제목',
        content: '수정된 내용',
      );

      blocTest<DiaryBloc, DiaryState>(
        '일기 수정 성공 시 목록에서 해당 엔트리 업데이트',
        build: () {
          when(() => mockUpdateDiary(any())).thenAnswer(
            (_) async => Right(updatedEntry),
          );
          return bloc;
        },
        seed: () => DiaryState(entries: [testEntry1, testEntry2]),
        act: (bloc) => bloc.add(DiaryEvent.updateEntry(updatedEntry)),
        expect: () => [
          // 로딩 시작
          isA<DiaryState>().having((s) => s.isLoading, 'isLoading', true),
          // 수정 완료
          isA<DiaryState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.entries.length, 'entries length', 2)
              .having((s) => s.entries[0].title, 'first entry title', '수정된 제목')
              .having(
                  (s) => s.entries[0].content, 'first entry content', '수정된 내용'),
        ],
        verify: (_) {
          verify(() => mockUpdateDiary(updatedEntry)).called(1);
        },
      );
    });

    group('일기 삭제 (DeleteDiaryEntry)', () {
      blocTest<DiaryBloc, DiaryState>(
        '일기 삭제 성공 시 목록에서 제거',
        build: () {
          when(() => mockDeleteDiary(any())).thenAnswer(
            (_) async => const Right(unit),
          );
          return bloc;
        },
        seed: () => DiaryState(entries: [testEntry1, testEntry2]),
        act: (bloc) => bloc.add(const DiaryEvent.deleteEntry('entry-1')),
        expect: () => [
          // 로딩 시작
          isA<DiaryState>().having((s) => s.isLoading, 'isLoading', true),
          // 삭제 완료
          isA<DiaryState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.entries.length, 'entries length', 1)
              .having((s) => s.entries.first, 'remaining entry', testEntry2),
        ],
        verify: (_) {
          verify(() => mockDeleteDiary('entry-1')).called(1);
        },
      );
    });

    group('검색 (SearchByKeyword)', () {
      blocTest<DiaryBloc, DiaryState>(
        '키워드 검색 성공',
        build: () {
          when(() => mockSearchDiaries(any())).thenAnswer(
            (_) async => Right([testEntry1]),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const DiaryEvent.searchByKeyword('날씨')),
        expect: () => [
          // 검색 키워드 설정 및 로딩 시작
          isA<DiaryState>()
              .having((s) => s.searchKeyword, 'searchKeyword', '날씨')
              .having((s) => s.isLoading, 'isLoading', true),
          // 검색 결과 로드 (아직 isLoading은 true)
          isA<DiaryState>()
              .having((s) => s.entries.length, 'entries length', 1)
              .having((s) => s.hasReachedEnd, 'hasReachedEnd', true),
          // 로딩 종료
          isA<DiaryState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.entries.length, 'entries length', 1),
        ],
        verify: (_) {
          verify(() => mockSearchDiaries(any())).called(1);
        },
      );

      blocTest<DiaryBloc, DiaryState>(
        '빈 키워드로 검색 시 아무 동작 안함',
        build: () => bloc,
        act: (bloc) => bloc.add(const DiaryEvent.searchByKeyword('')),
        expect: () => [
          // 검색 키워드만 설정되고 로딩 시작
          isA<DiaryState>()
              .having((s) => s.searchKeyword, 'searchKeyword', '')
              .having((s) => s.isLoading, 'isLoading', true),
          // 로딩 종료 (검색 실행 안함)
          isA<DiaryState>().having((s) => s.isLoading, 'isLoading', false),
        ],
        verify: (_) {
          verifyNever(() => mockSearchDiaries(any()));
        },
      );
    });

    group('페이지네이션 (LoadMoreDiaryEntries)', () {
      blocTest<DiaryBloc, DiaryState>(
        '추가 일기 로드 성공',
        build: () {
          when(() => mockGetDiaries(any())).thenAnswer(
            (_) async => Right([testEntry2]),
          );
          return bloc;
        },
        seed: () => DiaryState(entries: [testEntry1]),
        act: (bloc) => bloc.add(const DiaryEvent.loadMoreEntries()),
        expect: () => [
          // 추가 로딩 시작
          isA<DiaryState>()
              .having((s) => s.isLoadingMore, 'isLoadingMore', true),
          // 추가 데이터 로드 (아직 isLoadingMore는 true)
          isA<DiaryState>()
              .having((s) => s.entries.length, 'entries length', 2)
              .having((s) => s.currentPage, 'currentPage', 2),
          // 추가 로딩 종료
          isA<DiaryState>()
              .having((s) => s.isLoadingMore, 'isLoadingMore', false)
              .having((s) => s.entries.length, 'entries length', 2),
        ],
      );

      blocTest<DiaryBloc, DiaryState>(
        '마지막 페이지에 도달했을 때 추가 로드 무시',
        build: () => bloc,
        seed: () => const DiaryState(hasReachedEnd: true),
        act: (bloc) => bloc.add(const DiaryEvent.loadMoreEntries()),
        expect: () => [],
        verify: (_) {
          verifyNever(() => mockGetDiaries(any()));
        },
      );
    });

    group('필터 (FilterByTag)', () {
      blocTest<DiaryBloc, DiaryState>(
        '태그로 필터링',
        build: () => bloc,
        seed: () => DiaryState(entries: [testEntry1, testEntry2]),
        act: (bloc) => bloc.add(const DiaryEvent.filterByTag('tag-1')),
        expect: () => [
          // 필터 설정 및 로딩 시작
          isA<DiaryState>()
              .having((s) => s.filterTagId, 'filterTagId', 'tag-1')
              .having((s) => s.isLoading, 'isLoading', true),
          // 필터링 완료
          isA<DiaryState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.entries.length, 'entries length', 1)
              .having((s) => s.entries.first.tags.first.id, 'tag id', 'tag-1'),
        ],
      );
    });

    group('필터 초기화 (ClearFilters)', () {
      blocTest<DiaryBloc, DiaryState>(
        '필터 초기화 후 재로드',
        build: () {
          when(() => mockGetDiaries(any())).thenAnswer(
            (_) async => Right([testEntry1, testEntry2]),
          );
          return bloc;
        },
        seed: () => const DiaryState(
          searchKeyword: '검색어',
          filterTagId: 'tag-1',
        ),
        act: (bloc) => bloc.add(const DiaryEvent.clearFilters()),
        expect: () => [
          // 필터 초기화
          isA<DiaryState>()
              .having((s) => s.searchKeyword, 'searchKeyword', isNull)
              .having((s) => s.filterTagId, 'filterTagId', isNull),
          // 재로드 시작
          isA<DiaryState>().having((s) => s.isLoading, 'isLoading', true),
          // 데이터 로드 (아직 isLoading은 true)
          isA<DiaryState>()
              .having((s) => s.entries.length, 'entries length', 2),
          // 재로드 완료
          isA<DiaryState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.entries.length, 'entries length', 2),
        ],
      );
    });
  });
}
