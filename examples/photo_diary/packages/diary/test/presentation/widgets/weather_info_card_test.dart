import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diary/presentation/widgets/weather_info_card.dart';
import 'package:core/core.dart';

void main() {
  group('WeatherInfoCard', () {
    const testWeather = WeatherInfo(
      condition: 'Clear',
      temperature: 25.0,
      iconUrl: 'https://example.com/icon.png',
      humidity: 60.0,
    );

    const testWeatherWithoutHumidity = WeatherInfo(
      condition: 'Cloudy',
      temperature: 20.0,
      iconUrl: 'https://example.com/icon.png',
    );

    testWidgets('일반 모드에서 온도, 상태, 습도를 표시한다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WeatherInfoCard(
              weather: testWeather,
              compact: false,
            ),
          ),
        ),
      );

      // 온도 확인
      expect(find.text('25°C'), findsOneWidget);

      // 상태 확인
      expect(find.text('Clear'), findsOneWidget);

      // 습도 확인
      expect(find.text('습도: 60%'), findsOneWidget);

      // Card 위젯이 있는지 확인
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('습도가 없을 때 습도 정보를 표시하지 않는다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WeatherInfoCard(
              weather: testWeatherWithoutHumidity,
              compact: false,
            ),
          ),
        ),
      );

      // 온도, 상태만 확인
      expect(find.text('20°C'), findsOneWidget);
      expect(find.text('Cloudy'), findsOneWidget);

      // 습도는 표시되지 않음
      expect(find.textContaining('습도:'), findsNothing);
    });

    testWidgets('컴팩트 모드에서 아이콘과 온도만 표시한다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WeatherInfoCard(
              weather: testWeather,
              compact: true,
            ),
          ),
        ),
      );

      // 온도 확인 (컴팩트 모드에서는 °C 없이 °만 표시)
      expect(find.text('25°'), findsOneWidget);

      // 상태와 습도는 표시되지 않음
      expect(find.text('Clear'), findsNothing);
      expect(find.textContaining('습도:'), findsNothing);

      // Card는 표시되지 않음 (컴팩트 모드는 Row만 사용)
      expect(find.byType(Card), findsNothing);

      // Row는 표시됨
      expect(find.byType(Row), findsOneWidget);
    });

    testWidgets('맑음(clear) 날씨 아이콘을 표시한다', (tester) async {
      const weather = WeatherInfo(
        condition: 'Clear',
        temperature: 25.0,
        iconUrl: 'https://example.com/icon.png',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WeatherInfoCard(weather: weather),
          ),
        ),
      );

      expect(find.byIcon(Icons.wb_sunny), findsOneWidget);
    });

    testWidgets('맑음(맑음) 한글 날씨 아이콘을 표시한다', (tester) async {
      const weather = WeatherInfo(
        condition: '맑음',
        temperature: 25.0,
        iconUrl: 'https://example.com/icon.png',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WeatherInfoCard(weather: weather),
          ),
        ),
      );

      expect(find.byIcon(Icons.wb_sunny), findsOneWidget);
    });

    testWidgets('구름(cloud) 날씨 아이콘을 표시한다', (tester) async {
      const weather = WeatherInfo(
        condition: 'Cloudy',
        temperature: 20.0,
        iconUrl: 'https://example.com/icon.png',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WeatherInfoCard(weather: weather),
          ),
        ),
      );

      expect(find.byIcon(Icons.wb_cloudy), findsOneWidget);
    });

    testWidgets('구름(구름) 한글 날씨 아이콘을 표시한다', (tester) async {
      const weather = WeatherInfo(
        condition: '구름',
        temperature: 20.0,
        iconUrl: 'https://example.com/icon.png',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WeatherInfoCard(weather: weather),
          ),
        ),
      );

      expect(find.byIcon(Icons.wb_cloudy), findsOneWidget);
    });

    testWidgets('비(rain) 날씨 아이콘을 표시한다', (tester) async {
      const weather = WeatherInfo(
        condition: 'Rain',
        temperature: 15.0,
        iconUrl: 'https://example.com/icon.png',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WeatherInfoCard(weather: weather),
          ),
        ),
      );

      expect(find.byIcon(Icons.umbrella), findsOneWidget);
    });

    testWidgets('비(비) 한글 날씨 아이콘을 표시한다', (tester) async {
      const weather = WeatherInfo(
        condition: '비',
        temperature: 15.0,
        iconUrl: 'https://example.com/icon.png',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WeatherInfoCard(weather: weather),
          ),
        ),
      );

      expect(find.byIcon(Icons.umbrella), findsOneWidget);
    });

    testWidgets('눈(snow) 날씨 아이콘을 표시한다', (tester) async {
      const weather = WeatherInfo(
        condition: 'Snow',
        temperature: -5.0,
        iconUrl: 'https://example.com/icon.png',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WeatherInfoCard(weather: weather),
          ),
        ),
      );

      expect(find.byIcon(Icons.ac_unit), findsOneWidget);
    });

    testWidgets('눈(눈) 한글 날씨 아이콘을 표시한다', (tester) async {
      const weather = WeatherInfo(
        condition: '눈',
        temperature: -5.0,
        iconUrl: 'https://example.com/icon.png',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WeatherInfoCard(weather: weather),
          ),
        ),
      );

      expect(find.byIcon(Icons.ac_unit), findsOneWidget);
    });

    testWidgets('번개(thunder) 날씨 아이콘을 표시한다', (tester) async {
      const weather = WeatherInfo(
        condition: 'Thunderstorm',
        temperature: 18.0,
        iconUrl: 'https://example.com/icon.png',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WeatherInfoCard(weather: weather),
          ),
        ),
      );

      expect(find.byIcon(Icons.flash_on), findsOneWidget);
    });

    testWidgets('번개(번개) 한글 날씨 아이콘을 표시한다', (tester) async {
      const weather = WeatherInfo(
        condition: '번개',
        temperature: 18.0,
        iconUrl: 'https://example.com/icon.png',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WeatherInfoCard(weather: weather),
          ),
        ),
      );

      expect(find.byIcon(Icons.flash_on), findsOneWidget);
    });

    testWidgets('안개(fog) 날씨 아이콘을 표시한다', (tester) async {
      const weather = WeatherInfo(
        condition: 'Fog',
        temperature: 10.0,
        iconUrl: 'https://example.com/icon.png',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WeatherInfoCard(weather: weather),
          ),
        ),
      );

      expect(find.byIcon(Icons.cloud), findsOneWidget);
    });

    testWidgets('안개(안개) 한글 날씨 아이콘을 표시한다', (tester) async {
      const weather = WeatherInfo(
        condition: '안개',
        temperature: 10.0,
        iconUrl: 'https://example.com/icon.png',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WeatherInfoCard(weather: weather),
          ),
        ),
      );

      expect(find.byIcon(Icons.cloud), findsOneWidget);
    });

    testWidgets('알 수 없는 날씨는 기본 맑음 아이콘을 표시한다', (tester) async {
      const weather = WeatherInfo(
        condition: 'Unknown',
        temperature: 22.0,
        iconUrl: 'https://example.com/icon.png',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WeatherInfoCard(weather: weather),
          ),
        ),
      );

      expect(find.byIcon(Icons.wb_sunny), findsOneWidget);
    });

    testWidgets('컴팩트 모드에서 작은 아이콘을 사용한다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WeatherInfoCard(
              weather: testWeather,
              compact: true,
            ),
          ),
        ),
      );

      final iconWidget = tester.widget<Icon>(find.byType(Icon));
      expect(iconWidget.size, equals(20.0));
    });

    testWidgets('일반 모드에서 큰 아이콘을 사용한다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WeatherInfoCard(
              weather: testWeather,
              compact: false,
            ),
          ),
        ),
      );

      final iconWidget = tester.widget<Icon>(find.byType(Icon));
      expect(iconWidget.size, equals(48.0));
    });
  });
}
