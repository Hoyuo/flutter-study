import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:weather/domain/entities/weather.dart';
import 'package:weather/domain/repositories/weather_repository.dart';
import 'package:weather/domain/usecases/get_current_weather_usecase.dart';

class MockWeatherRepository extends Mock implements WeatherRepository {}

void main() {
  late GetCurrentWeatherUseCase useCase;
  late MockWeatherRepository mockRepository;

  setUp(() {
    mockRepository = MockWeatherRepository();
    useCase = GetCurrentWeatherUseCase(mockRepository);
  });

  group('GetCurrentWeatherUseCase', () {
    final testWeather = Weather(
      condition: 'Clear',
      description: 'clear sky',
      temperature: 25.0,
      humidity: 60,
      iconCode: '01d',
      iconUrl: 'https://openweathermap.org/img/wn/01d@2x.png',
      cityName: 'Seoul',
      timestamp: DateTime(2024, 1, 1, 12, 0),
    );

    group('좌표로 날씨 조회', () {
      test('성공 시 Weather 반환', () async {
        // arrange
        const params = GetCurrentWeatherParams.fromCoordinates(
          lat: 37.5665,
          lon: 126.9780,
        );
        when(() => mockRepository.getCurrentWeather(
              lat: any(named: 'lat'),
              lon: any(named: 'lon'),
            )).thenAnswer((_) async => Right(testWeather));

        // act
        final result = await useCase(params);

        // assert
        expect(result, Right(testWeather));
        verify(() => mockRepository.getCurrentWeather(
              lat: 37.5665,
              lon: 126.9780,
            )).called(1);
      });

      test('잘못된 좌표 시 ServerFailure 반환', () async {
        // arrange
        const params = GetCurrentWeatherParams.fromCoordinates(
          lat: 999.0,
          lon: 999.0,
        );
        const failure = Failure.server(
          message: '잘못된 좌표입니다',
          statusCode: 400,
        );
        when(() => mockRepository.getCurrentWeather(
              lat: any(named: 'lat'),
              lon: any(named: 'lon'),
            )).thenAnswer((_) async => const Left(failure));

        // act
        final result = await useCase(params);

        // assert
        expect(result, const Left(failure));
      });
    });

    group('도시 이름으로 날씨 조회', () {
      test('성공 시 Weather 반환', () async {
        // arrange
        const params = GetCurrentWeatherParams.fromCity(
          cityName: 'Seoul',
        );
        when(() => mockRepository.getWeatherByCity(
              cityName: any(named: 'cityName'),
            )).thenAnswer((_) async => Right(testWeather));

        // act
        final result = await useCase(params);

        // assert
        expect(result, Right(testWeather));
        verify(() => mockRepository.getWeatherByCity(
              cityName: 'Seoul',
            )).called(1);
      });

      test('존재하지 않는 도시 시 ServerFailure 반환', () async {
        // arrange
        const params = GetCurrentWeatherParams.fromCity(
          cityName: 'NonExistentCity',
        );
        const failure = Failure.server(
          message: '도시를 찾을 수 없습니다',
          statusCode: 404,
        );
        when(() => mockRepository.getWeatherByCity(
              cityName: any(named: 'cityName'),
            )).thenAnswer((_) async => const Left(failure));

        // act
        final result = await useCase(params);

        // assert
        expect(result, const Left(failure));
      });
    });

    group('파라미터 검증', () {
      test('좌표와 도시 이름 모두 없으면 UnknownFailure 반환', () async {
        // arrange
        const params = GetCurrentWeatherParams();

        // act
        final result = await useCase(params);

        // assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<UnknownFailure>());
          },
          (_) => fail('Should return failure'),
        );
      });

      test('lat만 있고 lon이 없으면 UnknownFailure 반환', () async {
        // arrange
        const params = GetCurrentWeatherParams(lat: 37.5665);

        // act
        final result = await useCase(params);

        // assert
        expect(result.isLeft(), true);
      });

      test('lon만 있고 lat이 없으면 UnknownFailure 반환', () async {
        // arrange
        const params = GetCurrentWeatherParams(lon: 126.9780);

        // act
        final result = await useCase(params);

        // assert
        expect(result.isLeft(), true);
      });
    });

    group('네트워크 에러', () {
      test('네트워크 에러 시 NetworkFailure 반환', () async {
        // arrange
        const params = GetCurrentWeatherParams.fromCity(cityName: 'Seoul');
        const failure = Failure.network(message: '네트워크 연결 실패');
        when(() => mockRepository.getWeatherByCity(
              cityName: any(named: 'cityName'),
            )).thenAnswer((_) async => const Left(failure));

        // act
        final result = await useCase(params);

        // assert
        expect(result, const Left(failure));
      });

      test('API 키 오류 시 AuthFailure 반환', () async {
        // arrange
        const params = GetCurrentWeatherParams.fromCity(cityName: 'Seoul');
        const failure = Failure.auth(
          message: '유효하지 않은 API 키입니다',
          errorCode: 'invalid_api_key',
        );
        when(() => mockRepository.getWeatherByCity(
              cityName: any(named: 'cityName'),
            )).thenAnswer((_) async => const Left(failure));

        // act
        final result = await useCase(params);

        // assert
        expect(result, const Left(failure));
      });
    });
  });
}
