import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:weather/domain/entities/entities.dart';
import 'package:weather/domain/usecases/usecases.dart';
import 'package:weather/presentation/bloc/weather_bloc.dart';
import 'package:weather/presentation/bloc/weather_event.dart';
import 'package:weather/presentation/bloc/weather_state.dart';

// Mock 클래스
class MockGetCurrentWeatherUseCase extends Mock
    implements GetCurrentWeatherUseCase {}

// Fake 클래스
class FakeGetCurrentWeatherParams extends Fake
    implements GetCurrentWeatherParams {}

void main() {
  late WeatherBloc bloc;
  late MockGetCurrentWeatherUseCase mockGetCurrentWeather;

  // 테스트용 Weather 데이터
  final testWeather = Weather(
    condition: 'Clear',
    description: '맑음',
    temperature: 23.5,
    humidity: 65,
    iconCode: '01d',
    iconUrl: 'https://openweathermap.org/img/wn/01d@2x.png',
    cityName: '서울',
    timestamp: DateTime(2024, 1, 1, 12, 0),
  );

  setUpAll(() {
    // Fake 클래스 등록
    registerFallbackValue(FakeGetCurrentWeatherParams());
  });

  setUp(() {
    mockGetCurrentWeather = MockGetCurrentWeatherUseCase();
    bloc = WeatherBloc(getCurrentWeatherUseCase: mockGetCurrentWeather);
  });

  tearDown(() => bloc.close());

  group('WeatherBloc', () {
    test('초기 상태 확인', () {
      expect(bloc.state.weather, isNull);
      expect(bloc.state.isLoading, isFalse);
      expect(bloc.state.failure, isNull);
      expect(bloc.state.lastUpdated, isNull);
    });

    group('현재 날씨 조회 (FetchCurrentWeather)', () {
      blocTest<WeatherBloc, WeatherState>(
        '날씨 조회 성공',
        build: () {
          when(() => mockGetCurrentWeather(any())).thenAnswer(
            (_) async => Right(testWeather),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const WeatherEvent.fetchCurrentWeather(
          latitude: 37.5665,
          longitude: 126.9780,
        )),
        expect: () => [
          // 로딩 시작
          isA<WeatherState>()
              .having((s) => s.isLoading, 'isLoading', true)
              .having((s) => s.failure, 'failure', isNull),
          // 조회 완료
          isA<WeatherState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.weather, 'weather', testWeather)
              .having((s) => s.failure, 'failure', isNull)
              .having((s) => s.lastUpdated, 'lastUpdated', isNotNull),
        ],
        verify: (_) {
          verify(() => mockGetCurrentWeather(any())).called(1);
        },
      );

      blocTest<WeatherBloc, WeatherState>(
        '날씨 조회 실패 - 네트워크 오류',
        build: () {
          when(() => mockGetCurrentWeather(any())).thenAnswer(
            (_) async => const Left(Failure.network(message: '인터넷 연결을 확인하세요')),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const WeatherEvent.fetchCurrentWeather(
          latitude: 37.5665,
          longitude: 126.9780,
        )),
        expect: () => [
          // 로딩 시작
          isA<WeatherState>().having((s) => s.isLoading, 'isLoading', true),
          // 조회 실패
          isA<WeatherState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.weather, 'weather', isNull)
              .having((s) => s.failure, 'failure', isNotNull)
              .having((s) => s.failure?.message, 'failure message',
                  '인터넷 연결을 확인하세요'),
        ],
      );

      blocTest<WeatherBloc, WeatherState>(
        '날씨 조회 실패 - API 오류',
        build: () {
          when(() => mockGetCurrentWeather(any())).thenAnswer(
            (_) async => const Left(
                Failure.server(message: 'API 키가 유효하지 않습니다', statusCode: 401)),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const WeatherEvent.fetchCurrentWeather(
          latitude: 37.5665,
          longitude: 126.9780,
        )),
        expect: () => [
          // 로딩 시작
          isA<WeatherState>().having((s) => s.isLoading, 'isLoading', true),
          // 조회 실패
          isA<WeatherState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.failure, 'failure', isNotNull)
              .having((s) => s.failure?.message, 'failure message',
                  'API 키가 유효하지 않습니다'),
        ],
      );

      blocTest<WeatherBloc, WeatherState>(
        '날씨 조회 실패 - 인증 오류',
        build: () {
          when(() => mockGetCurrentWeather(any())).thenAnswer(
            (_) async => const Left(Failure.auth(message: '인증이 필요합니다')),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const WeatherEvent.fetchCurrentWeather(
          latitude: 37.5665,
          longitude: 126.9780,
        )),
        expect: () => [
          // 로딩 시작
          isA<WeatherState>().having((s) => s.isLoading, 'isLoading', true),
          // 조회 실패
          isA<WeatherState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.failure, 'failure', isNotNull)
              .having((s) => s.failure?.message, 'failure message', '인증이 필요합니다'),
        ],
      );

      blocTest<WeatherBloc, WeatherState>(
        '날씨 조회 실패 - 캐시 오류',
        build: () {
          when(() => mockGetCurrentWeather(any())).thenAnswer(
            (_) async => const Left(Failure.cache(message: '캐시를 읽을 수 없습니다')),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const WeatherEvent.fetchCurrentWeather(
          latitude: 37.5665,
          longitude: 126.9780,
        )),
        expect: () => [
          // 로딩 시작
          isA<WeatherState>().having((s) => s.isLoading, 'isLoading', true),
          // 조회 실패
          isA<WeatherState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.failure, 'failure', isNotNull)
              .having((s) => s.failure?.message, 'failure message',
                  '캐시를 읽을 수 없습니다'),
        ],
      );

      blocTest<WeatherBloc, WeatherState>(
        '날씨 조회 실패 - 알 수 없는 오류',
        build: () {
          when(() => mockGetCurrentWeather(any())).thenAnswer(
            (_) async => const Left(Failure.unknown(message: '예기치 않은 오류가 발생했습니다')),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const WeatherEvent.fetchCurrentWeather(
          latitude: 37.5665,
          longitude: 126.9780,
        )),
        expect: () => [
          // 로딩 시작
          isA<WeatherState>().having((s) => s.isLoading, 'isLoading', true),
          // 조회 실패
          isA<WeatherState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.failure, 'failure', isNotNull)
              .having((s) => s.failure?.message, 'failure message',
                  '예기치 않은 오류가 발생했습니다'),
        ],
      );
    });

    group('날씨 정보 새로고침 (RefreshWeather)', () {
      blocTest<WeatherBloc, WeatherState>(
        '날씨 새로고침 성공',
        build: () {
          when(() => mockGetCurrentWeather(any())).thenAnswer(
            (_) async => Right(testWeather.copyWith(temperature: 25.0)),
          );
          return bloc;
        },
        seed: () => WeatherState(
          weather: testWeather,
          lastUpdated: DateTime(2024, 1, 1, 11, 0),
        ),
        act: (bloc) => bloc.add(const WeatherEvent.refreshWeather()),
        expect: () => [
          // 로딩 시작
          isA<WeatherState>()
              .having((s) => s.isLoading, 'isLoading', true)
              .having((s) => s.weather, 'weather', testWeather),
          // 새로고침 완료
          isA<WeatherState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.weather?.temperature, 'temperature', 25.0)
              .having((s) => s.failure, 'failure', isNull)
              .having((s) => s.lastUpdated, 'lastUpdated', isNotNull),
        ],
        verify: (_) {
          verify(() => mockGetCurrentWeather(any())).called(1);
        },
      );

      blocTest<WeatherBloc, WeatherState>(
        '현재 날씨 정보가 없을 때 새로고침 무시',
        build: () => bloc,
        act: (bloc) => bloc.add(const WeatherEvent.refreshWeather()),
        expect: () => [],
        verify: (_) {
          verifyNever(() => mockGetCurrentWeather(any()));
        },
      );

      blocTest<WeatherBloc, WeatherState>(
        '새로고침 실패',
        build: () {
          when(() => mockGetCurrentWeather(any())).thenAnswer(
            (_) async => const Left(Failure.network(message: '연결 시간 초과')),
          );
          return bloc;
        },
        seed: () => WeatherState(
          weather: testWeather,
          lastUpdated: DateTime(2024, 1, 1, 11, 0),
        ),
        act: (bloc) => bloc.add(const WeatherEvent.refreshWeather()),
        expect: () => [
          // 로딩 시작
          isA<WeatherState>().having((s) => s.isLoading, 'isLoading', true),
          // 새로고침 실패 (기존 날씨 정보 유지)
          isA<WeatherState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.weather, 'weather', testWeather)
              .having((s) => s.failure, 'failure', isNotNull)
              .having((s) => s.failure?.message, 'failure message', '연결 시간 초과'),
        ],
      );
    });

    group('날씨 정보 초기화 (ClearWeather)', () {
      blocTest<WeatherBloc, WeatherState>(
        '날씨 정보 초기화 성공',
        build: () => bloc,
        seed: () => WeatherState(
          weather: testWeather,
          lastUpdated: DateTime.now(),
        ),
        act: (bloc) => bloc.add(const WeatherEvent.clearWeather()),
        expect: () => [
          // 초기 상태로 복원
          isA<WeatherState>()
              .having((s) => s.weather, 'weather', isNull)
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.failure, 'failure', isNull)
              .having((s) => s.lastUpdated, 'lastUpdated', isNull),
        ],
      );
    });

    group('다양한 시나리오', () {
      blocTest<WeatherBloc, WeatherState>(
        '연속된 날씨 조회 - 마지막 결과가 반영됨',
        build: () {
          when(() => mockGetCurrentWeather(any())).thenAnswer(
            (_) async => Right(testWeather),
          );
          return bloc;
        },
        act: (bloc) async {
          bloc.add(const WeatherEvent.fetchCurrentWeather(
            latitude: 37.5665,
            longitude: 126.9780,
          ));
          await Future.delayed(const Duration(milliseconds: 100));
          bloc.add(const WeatherEvent.fetchCurrentWeather(
            latitude: 35.1796,
            longitude: 129.0756,
          ));
        },
        skip: 2, // 첫 번째 조회 결과는 건너뜀
        expect: () => [
          // 두 번째 조회 - 로딩 시작
          isA<WeatherState>().having((s) => s.isLoading, 'isLoading', true),
          // 두 번째 조회 완료
          isA<WeatherState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.weather, 'weather', testWeather),
        ],
      );

      blocTest<WeatherBloc, WeatherState>(
        '날씨 조회 후 초기화',
        build: () {
          when(() => mockGetCurrentWeather(any())).thenAnswer(
            (_) async => Right(testWeather),
          );
          return bloc;
        },
        act: (bloc) async {
          bloc.add(const WeatherEvent.fetchCurrentWeather(
            latitude: 37.5665,
            longitude: 126.9780,
          ));
          await Future.delayed(const Duration(milliseconds: 100));
          bloc.add(const WeatherEvent.clearWeather());
        },
        skip: 2, // 날씨 조회 결과는 건너뜀
        expect: () => [
          // 초기화
          isA<WeatherState>()
              .having((s) => s.weather, 'weather', isNull)
              .having((s) => s.lastUpdated, 'lastUpdated', isNull),
        ],
      );
    });
  });
}
