import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// TODO: network_image_mock 패키지 추가 필요
// import 'package:network_image_mock/network_image_mock.dart';
import 'package:diary/domain/entities/entities.dart';
import 'package:diary/presentation/widgets/diary_card.dart';
import 'package:diary/presentation/widgets/weather_info_card.dart';
import 'package:core/core.dart';

// 임시 헬퍼 함수 (network_image_mock 패키지 없이 테스트 실행)
Future<void> mockNetworkImagesFor(Future<void> Function() body) async {
  await body();
}

void main() {
  group('DiaryCard', () {
    // 테스트용 DiaryEntry 생성
    final testEntry = DiaryEntry(
      id: '1',
      userId: 'user_1',
      title: '오늘의 일기',
      content: '오늘 좋은 하루였다',
      photoUrls: ['https://example.com/photo.jpg'],
      tags: [
        const Tag(
          id: '1',
          name: '행복',
          colorHex: '#FF5722',
          userId: 'user_1',
        ),
      ],
      weather: const WeatherInfo(
        condition: 'Clear',
        temperature: 25.0,
        iconUrl: 'https://example.com/icon.png',
      ),
      createdAt: DateTime(2026, 1, 27, 14, 30),
      updatedAt: DateTime(2026, 1, 27, 14, 30),
    );

    testWidgets('제목이 표시된다', (tester) async {
      // 네트워크 이미지 모킹
      await mockNetworkImagesFor(() async {
        // Widget 빌드
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DiaryCard(
                entry: testEntry,
                onTap: () {},
              ),
            ),
          ),
        );

        // 제목 텍스트가 표시되는지 확인
        expect(find.text('오늘의 일기'), findsOneWidget);
      });
    });

    testWidgets('태그가 표시된다', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DiaryCard(
                entry: testEntry,
                onTap: () {},
              ),
            ),
          ),
        );

        // 태그가 표시되는지 확인
        expect(find.text('행복'), findsOneWidget);
      });
    });

    testWidgets('날짜가 표시된다', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DiaryCard(
                entry: testEntry,
                onTap: () {},
              ),
            ),
          ),
        );

        // 날짜 텍스트가 표시되는지 확인 (포맷된 날짜)
        // _formatDate: 오늘/어제면 "오늘 HH:mm"/"어제 HH:mm", 그 외엔 "YYYY년 M월 D일"
        // testEntry의 createdAt: DateTime(2026, 1, 27, 14, 30)
        // 현재 날짜에 따라 다른 포맷이 표시될 수 있음
        final dateTexts = [
          '오늘',
          '어제',
          '2026년 1월 27일',
        ];
        final found = dateTexts.any(
            (text) => tester.widgetList(find.textContaining(text)).isNotEmpty);
        expect(found, isTrue,
            reason: '날짜 텍스트(오늘/어제/2026년 1월 27일 중 하나)가 표시되어야 함');
      });
    });

    testWidgets('사진이 없으면 플레이스홀더가 표시된다', (tester) async {
      // 사진 없는 일기 엔트리
      final entryWithoutPhoto = DiaryEntry(
        id: '2',
        userId: 'user_1',
        title: '사진 없는 일기',
        content: '텍스트만 작성',
        photoUrls: [],
        tags: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DiaryCard(
                entry: entryWithoutPhoto,
                onTap: () {},
              ),
            ),
          ),
        );

        // 플레이스홀더 아이콘이 표시되는지 확인
        expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
      });
    });

    testWidgets('탭 시 콜백이 호출된다', (tester) async {
      var tapped = false;

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DiaryCard(
                entry: testEntry,
                onTap: () => tapped = true,
              ),
            ),
          ),
        );

        // DiaryCard 탭 (Card 내부의 InkWell을 찾음)
        await tester.tap(find.byType(DiaryCard));
        await tester.pumpAndSettle();

        // 콜백이 호출되었는지 확인
        expect(tapped, isTrue);
      });
    });

    testWidgets('Semantics가 올바르게 설정된다', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DiaryCard(
                entry: testEntry,
                onTap: () {},
              ),
            ),
          ),
        );

        // Semantics 확인
        final semanticsFinder = find.bySemanticsLabel(
          RegExp(r'일기:.*오늘의 일기.*'),
        );
        expect(semanticsFinder, findsOneWidget);
      });
    });

    testWidgets('최대 3개의 태그만 표시된다', (tester) async {
      // 4개의 태그를 가진 일기
      final entryWithManyTags = DiaryEntry(
        id: '3',
        userId: 'user_1',
        title: '태그 많은 일기',
        content: '내용',
        photoUrls: [],
        tags: [
          const Tag(
            id: '1',
            name: '태그1',
            colorHex: '#FF5722',
            userId: 'user_1',
          ),
          const Tag(
            id: '2',
            name: '태그2',
            colorHex: '#FF5722',
            userId: 'user_1',
          ),
          const Tag(
            id: '3',
            name: '태그3',
            colorHex: '#FF5722',
            userId: 'user_1',
          ),
          const Tag(
            id: '4',
            name: '태그4',
            colorHex: '#FF5722',
            userId: 'user_1',
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DiaryCard(
                entry: entryWithManyTags,
                onTap: () {},
              ),
            ),
          ),
        );

        // Chip 개수 확인 (최대 3개)
        expect(find.byType(Chip), findsNWidgets(3));
        // 4번째 태그는 표시되지 않음
        expect(find.text('태그4'), findsNothing);
      });
    });

    testWidgets('어제 작성된 일기는 "어제" 포맷으로 표시된다', (tester) async {
      // 어제 날짜로 일기 생성
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final yesterdayWithTime = DateTime(
        yesterday.year,
        yesterday.month,
        yesterday.day,
        14,
        30,
      );

      final yesterdayEntry = DiaryEntry(
        id: '4',
        userId: 'user_1',
        title: '어제의 일기',
        content: '어제 좋은 하루였다',
        photoUrls: [],
        tags: [],
        createdAt: yesterdayWithTime,
        updatedAt: yesterdayWithTime,
      );

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DiaryCard(
                entry: yesterdayEntry,
                onTap: () {},
              ),
            ),
          ),
        );

        // "어제" 텍스트가 표시되는지 확인 (Semantics 포함하여 여러 개 있을 수 있음)
        expect(find.textContaining('어제'), findsAtLeastNWidgets(1));
      });
    });

    testWidgets('날씨 정보가 있으면 WeatherInfoCard를 표시한다', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DiaryCard(
                entry: testEntry,
                onTap: () {},
              ),
            ),
          ),
        );

        // WeatherInfoCard가 표시되는지 확인
        expect(find.byType(WeatherInfoCard), findsOneWidget);
      });
    });

    testWidgets('날씨 정보가 없으면 WeatherInfoCard를 표시하지 않는다', (tester) async {
      final entryWithoutWeather = DiaryEntry(
        id: '5',
        userId: 'user_1',
        title: '날씨 없는 일기',
        content: '내용',
        photoUrls: [],
        tags: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DiaryCard(
                entry: entryWithoutWeather,
                onTap: () {},
              ),
            ),
          ),
        );

        // WeatherInfoCard가 표시되지 않는지 확인
        expect(find.byType(WeatherInfoCard), findsNothing);
      });
    });
  });
}
