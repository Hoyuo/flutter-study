# Flutter Networking Guide - Part 2: Retrofit

> 이 문서는 Retrofit을 사용한 타입 안전한 API 클라이언트 구현 방법을 설명합니다.

> **학습 목표**: 이 문서를 학습하면 다음을 할 수 있습니다:
> - Retrofit 어노테이션으로 타입 안전한 API 클라이언트를 생성할 수 있다
> - json_serializable과 연동한 자동 직렬화/역직렬화를 구현할 수 있다
> - 멀티파트 업로드, 다운로드 등 고급 API 패턴을 적용할 수 있다

## 1. 개요

### 1.1 Retrofit이란?

Retrofit은 어노테이션 기반으로 HTTP API를 정의하는 타입 안전한 HTTP 클라이언트입니다.

| Dio만 사용 | Retrofit + Dio |
|-----------|---------------|
| 수동 URL/메서드 작성 | 어노테이션으로 선언적 정의 |
| 응답 수동 파싱 | 자동 JSON 파싱 |
| 타입 체크 없음 | 컴파일 타임 타입 체크 |
| 코드 중복 많음 | 간결한 인터페이스 |

### 1.2 언제 Retrofit을 사용할까?

```
✅ Retrofit 추천
├── REST API 엔드포인트가 많을 때
├── 타입 안전성이 중요할 때
├── 팀이 Android Retrofit에 익숙할 때
└── 일관된 API 정의가 필요할 때

❌ Dio만 사용
├── 간단한 API (엔드포인트 2-3개)
├── 동적 URL 처리가 많을 때
└── WebSocket, GraphQL 사용 시
```

## 2. 프로젝트 설정

### 2.1 의존성 추가

```yaml
# pubspec.yaml (2026년 1월 기준)
dependencies:
  dio: ^5.9.0
  retrofit: ^4.9.2
  json_annotation: ^4.9.0
  fpdart: ^1.2.0

dev_dependencies:
  retrofit_generator: ^10.2.1
  json_serializable: ^6.9.5
  build_runner: ^2.4.15
```

> **retrofit 4.9.0+ 주요 변경사항:**
> - `@BodyExtra` 어노테이션: 요청 body에 개별 필드 추가
> - `CallAdapters`: 반환 타입 변환 지원
> - lean_builder 실험적 지원 (빌드 속도 향상)
> - Dart 3.5 이상 필수

### 2.2 프로젝트 구조

```
features/{feature_name}/lib/
├── data/
│   ├── api/
│   │   └── home_api.dart           # Retrofit API 정의
│   ├── datasources/
│   │   └── home_remote_datasource.dart
│   ├── dto/
│   │   ├── home_dto.dart
│   │   ├── home_dto.g.dart         # json_serializable 생성
│   │   └── requests/
│   │       └── create_home_request.dart
│   └── ...
└── ...
```

## 3. API 클라이언트 정의

### 3.1 기본 API 정의

```dart
// features/home/lib/data/api/home_api.dart
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'home_api.g.dart';

@RestApi()
abstract class HomeApi {
  factory HomeApi(Dio dio, {String baseUrl}) = _HomeApi;

  @GET('/api/v1/home')
  Future<HomeDto> getHomeData();

  @GET('/api/v1/home/items')
  Future<HomeItemsResponse> getHomeItems(
    @Query('page') int page,
    @Query('limit') int limit,
  );

  @GET('/api/v1/home/items/{id}')
  Future<HomeItemDto> getHomeItem(@Path('id') String id);

  @POST('/api/v1/home/items')
  Future<HomeItemDto> createHomeItem(@Body() CreateHomeItemRequest request);

  @PUT('/api/v1/home/items/{id}')
  Future<HomeItemDto> updateHomeItem(
    @Path('id') String id,
    @Body() UpdateHomeItemRequest request,
  );

  @DELETE('/api/v1/home/items/{id}')
  Future<void> deleteHomeItem(@Path('id') String id);
}
```

### 3.2 어노테이션 종류

| 어노테이션 | 용도 | 예시 |
|-----------|------|------|
| `@GET` | GET 요청 | `@GET('/users')` |
| `@POST` | POST 요청 | `@POST('/users')` |
| `@PUT` | PUT 요청 | `@PUT('/users/{id}')` |
| `@PATCH` | PATCH 요청 | `@PATCH('/users/{id}')` |
| `@DELETE` | DELETE 요청 | `@DELETE('/users/{id}')` |
| `@Path` | URL 경로 변수 | `@Path('id') String id` |
| `@Query` | 쿼리 파라미터 | `@Query('page') int page` |
| `@Body` | 요청 본문 | `@Body() CreateRequest req` |
| `@Header` | 단일 헤더 | `@Header('X-Token') String token` |
| `@Headers` | 다중 헤더 | `@Headers({'Accept': 'application/json'})` |
| `@Field` | Form 필드 | `@Field('email') String email` |
| `@Part` | Multipart 필드 | `@Part() File file` |

## 4. DTO 정의

### 4.1 응답 DTO

```dart
// features/home/lib/data/dto/home_dto.dart
import 'package:json_annotation/json_annotation.dart';

part 'home_dto.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class HomeDto {
  final String id;
  final String title;
  final String? description;
  final DateTime createdAt;
  final DateTime? updatedAt;

  HomeDto({
    required this.id,
    required this.title,
    this.description,
    required this.createdAt,
    this.updatedAt,
  });

  factory HomeDto.fromJson(Map<String, dynamic> json) =>
      _$HomeDtoFromJson(json);

  Map<String, dynamic> toJson() => _$HomeDtoToJson(this);
}
```

### 4.2 리스트 응답 DTO

```dart
// features/home/lib/data/dto/home_items_response.dart
import 'package:json_annotation/json_annotation.dart';

part 'home_items_response.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class HomeItemsResponse {
  final List<HomeItemDto> items;
  final PaginationDto pagination;

  HomeItemsResponse({
    required this.items,
    required this.pagination,
  });

  factory HomeItemsResponse.fromJson(Map<String, dynamic> json) =>
      _$HomeItemsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$HomeItemsResponseToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class PaginationDto {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final bool hasNext;
  final bool hasPrevious;

  PaginationDto({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory PaginationDto.fromJson(Map<String, dynamic> json) =>
      _$PaginationDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PaginationDtoToJson(this);
}
```

### 4.3 요청 DTO

```dart
// features/home/lib/data/dto/requests/create_home_item_request.dart
import 'package:json_annotation/json_annotation.dart';

part 'create_home_item_request.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class CreateHomeItemRequest {
  final String title;
  final String? description;
  final List<String>? tags;

  CreateHomeItemRequest({
    required this.title,
    this.description,
    this.tags,
  });

  factory CreateHomeItemRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateHomeItemRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateHomeItemRequestToJson(this);
}
```

### 4.4 중첩 객체 처리

```dart
// features/home/lib/data/dto/home_detail_dto.dart
import 'package:json_annotation/json_annotation.dart';

part 'home_detail_dto.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class HomeDetailDto {
  final String id;
  final String title;
  final AuthorDto author;           // 중첩 객체
  final List<TagDto> tags;          // 중첩 리스트
  final Map<String, dynamic>? meta; // 동적 데이터

  HomeDetailDto({
    required this.id,
    required this.title,
    required this.author,
    required this.tags,
    this.meta,
  });

  factory HomeDetailDto.fromJson(Map<String, dynamic> json) =>
      _$HomeDetailDtoFromJson(json);

  Map<String, dynamic> toJson() => _$HomeDetailDtoToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class AuthorDto {
  final String id;
  final String name;
  final String? avatarUrl;

  AuthorDto({
    required this.id,
    required this.name,
    this.avatarUrl,
  });

  factory AuthorDto.fromJson(Map<String, dynamic> json) =>
      _$AuthorDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AuthorDtoToJson(this);
}
```

## 5. DI 연동

### 5.1 API 등록

```dart
// features/home/lib/src/injection.dart
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injection.config.dart';

@InjectableInit.microPackage()
void initHomePackage(GetIt getIt) => getIt.init();

@module
abstract class HomeApiModule {
  @lazySingleton
  HomeApi homeApi(Dio dio) => HomeApi(dio);
}
```

### 5.2 DataSource에서 사용

```dart
// features/home/lib/data/datasources/home_remote_datasource.dart
import 'package:injectable/injectable.dart';

abstract class HomeRemoteDataSource {
  Future<HomeDto> getHomeData();
  Future<HomeItemsResponse> getHomeItems({int page = 1, int limit = 20});
  Future<HomeItemDto> getHomeItem(String id);
  Future<HomeItemDto> createHomeItem(CreateHomeItemRequest request);
  Future<HomeItemDto> updateHomeItem(String id, UpdateHomeItemRequest request);
  Future<void> deleteHomeItem(String id);
}

@LazySingleton(as: HomeRemoteDataSource)
class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final HomeApi _api;

  HomeRemoteDataSourceImpl(this._api);

  @override
  Future<HomeDto> getHomeData() => _api.getHomeData();

  @override
  Future<HomeItemsResponse> getHomeItems({int page = 1, int limit = 20}) =>
      _api.getHomeItems(page, limit);

  @override
  Future<HomeItemDto> getHomeItem(String id) => _api.getHomeItem(id);

  @override
  Future<HomeItemDto> createHomeItem(CreateHomeItemRequest request) =>
      _api.createHomeItem(request);

  @override
  Future<HomeItemDto> updateHomeItem(String id, UpdateHomeItemRequest request) =>
      _api.updateHomeItem(id, request);

  @override
  Future<void> deleteHomeItem(String id) => _api.deleteHomeItem(id);
}
```

## 6. 고급 기능

### 6.1 파일 업로드

```dart
// features/profile/lib/data/api/profile_api.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:http_parser/http_parser.dart';

part 'profile_api.g.dart';

@RestApi()
abstract class ProfileApi {
  factory ProfileApi(Dio dio, {String baseUrl}) = _ProfileApi;

  @POST('/api/v1/profile/avatar')
  @MultiPart()
  Future<UploadResponse> uploadAvatar(
    @Part(name: 'file') File file,
  );

  @POST('/api/v1/files/upload')
  @MultiPart()
  Future<UploadResponse> uploadMultipleFiles(
    @Part(name: 'files') List<File> files,
  );

  @POST('/api/v1/profile/update')
  @MultiPart()
  Future<ProfileDto> updateProfileWithImage(
    @Part(name: 'name') String name,
    @Part(name: 'bio') String? bio,
    @Part(name: 'avatar') File? avatar,
  );
}
```

### 6.2 커스텀 헤더

```dart
@RestApi()
abstract class AuthApi {
  factory AuthApi(Dio dio, {String baseUrl}) = _AuthApi;

  // 단일 헤더
  @POST('/api/v1/auth/verify')
  Future<VerifyResponse> verifyToken(
    @Header('X-Verification-Token') String token,
  );

  // 다중 헤더
  @GET('/api/v1/protected/resource')
  @Headers({
    'X-Custom-Header': 'custom-value',
    'Cache-Control': 'no-cache',
  })
  Future<ResourceDto> getProtectedResource();
}
```

### 6.3 동적 URL

```dart
@RestApi()
abstract class DynamicApi {
  factory DynamicApi(Dio dio, {String baseUrl}) = _DynamicApi;

  // 전체 URL 오버라이드
  @GET('{url}')
  Future<dynamic> getFromUrl(@Path('url') String fullUrl);

  // 쿼리 파라미터 맵
  @GET('/api/v1/search')
  Future<SearchResponse> search(
    @Queries() Map<String, dynamic> queryParams,
  );
}
```

### 6.4 Form URL Encoded

```dart
@RestApi()
abstract class AuthApi {
  factory AuthApi(Dio dio, {String baseUrl}) = _AuthApi;

  @POST('/oauth/token')
  @FormUrlEncoded()
  Future<TokenResponse> getToken(
    @Field('grant_type') String grantType,
    @Field('username') String username,
    @Field('password') String password,
  );
}
```

### 6.5 Raw Response 접근

```dart
@RestApi()
abstract class FileApi {
  factory FileApi(Dio dio, {String baseUrl}) = _FileApi;

  // HttpResponse로 헤더 접근
  @GET('/api/v1/files/{id}')
  Future<HttpResponse<FileDto>> getFileWithHeaders(@Path('id') String id);

  // 다운로드 (바이트 스트림)
  @GET('/api/v1/files/{id}/download')
  @DioResponseType(ResponseType.bytes)
  Future<List<int>> downloadFile(@Path('id') String id);
}

// 사용
final response = await fileApi.getFileWithHeaders('123');
final fileDto = response.data;
final contentType = response.response.headers.value('content-type');
```

## 7. 에러 처리

### 7.1 Repository에서 처리

```dart
// features/home/lib/data/repositories/home_repository_impl.dart
import 'package:fpdart/fpdart.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: HomeRepository)
class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource _dataSource;
  final HomeMapper _mapper;

  HomeRepositoryImpl(this._dataSource, this._mapper);

  @override
  Future<Either<HomeFailure, HomeData>> getHomeData() async {
    try {
      final dto = await _dataSource.getHomeData();
      return Right(_mapper.toEntity(dto));
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return const Left(HomeFailure.unknown());
    }
  }

  @override
  Future<Either<HomeFailure, HomeItem>> createHomeItem(
    CreateHomeItemParams params,
  ) async {
    try {
      final request = CreateHomeItemRequest(
        title: params.title,
        description: params.description,
        tags: params.tags,
      );
      final dto = await _dataSource.createHomeItem(request);
      return Right(_mapper.itemToEntity(dto));
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return const Left(HomeFailure.unknown());
    }
  }

  HomeFailure _mapDioError(DioException e) {
    final error = e.error;

    // NetworkException이 있으면 사용
    // 주의: when()은 모든 케이스 필수, 일부만 처리하려면 maybeWhen() 사용
    if (error is NetworkException) {
      return error.maybeWhen(
        noConnection: () => const HomeFailure.network(),
        timeout: () => const HomeFailure.network(),
        unauthorized: () => const HomeFailure.unauthorized(),
        notFound: () => const HomeFailure.notFound(),
        validationError: (msg) => HomeFailure.validation(msg ?? 'Validation error'),
        serverError: (_, msg) => HomeFailure.server(msg ?? 'Server error'),
        orElse: () => const HomeFailure.unknown(),
      );
    }

    // DioException 직접 처리
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
        return const HomeFailure.network();
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode ?? 0;
        if (statusCode == 404) return const HomeFailure.notFound();
        if (statusCode == 401) return const HomeFailure.unauthorized();
        return HomeFailure.server('Error: $statusCode');
      default:
        return const HomeFailure.unknown();
    }
  }
}
```

## 8. 테스트

### 8.1 API Mock

```dart
// test/mocks/mocks.dart
// ⚠️ 주의: 이 프로젝트의 표준 모킹 라이브러리는 mocktail입니다 (mockito가 아님).
// mocktail 사용 시: class MockHomeApi extends Mock implements HomeApi {}
// when(() => mockApi.getUsers()).thenAnswer((_) async => [...]);
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([HomeApi, HomeRemoteDataSource])
import 'mocks.mocks.dart';
```

### 8.2 DataSource 테스트

```dart
// test/data/datasources/home_remote_datasource_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../fixtures/home_fixture.dart';
import '../../mocks/mocks.dart';

void main() {
  late HomeRemoteDataSourceImpl dataSource;
  late MockHomeApi mockApi;

  setUp(() {
    mockApi = MockHomeApi();
    dataSource = HomeRemoteDataSourceImpl(mockApi);
  });

  group('getHomeData', () {
    test('API 호출 성공 시 HomeDto 반환', () async {
      // Arrange
      final expected = HomeFixture.homeDto;
      when(mockApi.getHomeData())
          .thenAnswer((_) async => expected);

      // Act
      final result = await dataSource.getHomeData();

      // Assert
      expect(result, expected);
      verify(mockApi.getHomeData()).called(1);
    });
  });

  group('getHomeItems', () {
    test('페이지네이션 파라미터가 올바르게 전달됨', () async {
      // Arrange
      final expected = HomeFixture.homeItemsResponse;
      when(mockApi.getHomeItems(any, any))
          .thenAnswer((_) async => expected);

      // Act
      final result = await dataSource.getHomeItems(page: 2, limit: 10);

      // Assert
      expect(result, expected);
      verify(mockApi.getHomeItems(2, 10)).called(1);
    });
  });
}
```

## 9. JSON 직렬화 팁

### 9.1 build.yaml 설정

```yaml
# build.yaml
targets:
  $default:
    builders:
      json_serializable:
        options:
          # 전역 설정
          field_rename: snake
          explicit_to_json: true
          include_if_null: false
```

### 9.2 커스텀 컨버터

```dart
// core/core_network/lib/src/converters/datetime_converter.dart
import 'package:json_annotation/json_annotation.dart';

class DateTimeConverter implements JsonConverter<DateTime, String> {
  const DateTimeConverter();

  @override
  DateTime fromJson(String json) => DateTime.parse(json);

  @override
  String toJson(DateTime object) => object.toIso8601String();
}

class NullableDateTimeConverter implements JsonConverter<DateTime?, String?> {
  const NullableDateTimeConverter();

  @override
  DateTime? fromJson(String? json) => json != null ? DateTime.parse(json) : null;

  @override
  String? toJson(DateTime? object) => object?.toIso8601String();
}

// 사용
@JsonSerializable()
class EventDto {
  final String id;

  @DateTimeConverter()
  final DateTime startDate;

  @NullableDateTimeConverter()
  final DateTime? endDate;

  EventDto({required this.id, required this.startDate, this.endDate});

  factory EventDto.fromJson(Map<String, dynamic> json) =>
      _$EventDtoFromJson(json);
}
```

### 9.3 Enum 처리

```dart
// features/order/lib/data/dto/order_dto.dart
import 'package:json_annotation/json_annotation.dart';

part 'order_dto.g.dart';

@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum OrderStatus {
  @JsonValue('PENDING')
  pending,
  @JsonValue('CONFIRMED')
  confirmed,
  @JsonValue('SHIPPED')
  shipped,
  @JsonValue('DELIVERED')
  delivered,
  @JsonValue('CANCELLED')
  cancelled,
}

@JsonSerializable(fieldRename: FieldRename.snake)
class OrderDto {
  final String id;
  final OrderStatus status;
  final double totalAmount;

  OrderDto({
    required this.id,
    required this.status,
    required this.totalAmount,
  });

  factory OrderDto.fromJson(Map<String, dynamic> json) =>
      _$OrderDtoFromJson(json);

  Map<String, dynamic> toJson() => _$OrderDtoToJson(this);
}
```

### 9.4 Generic Response

```dart
// core/core_network/lib/src/dto/api_response.dart
import 'package:json_annotation/json_annotation.dart';

part 'api_response.g.dart';

@JsonSerializable(genericArgumentFactories: true)
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? errorCode;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.errorCode,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$ApiResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$ApiResponseToJson(this, toJsonT);
}

// Retrofit에서 사용
@RestApi()
abstract class HomeApi {
  factory HomeApi(Dio dio, {String baseUrl}) = _HomeApi;

  @GET('/api/v1/home')
  Future<ApiResponse<HomeDto>> getHomeData();
}
```

## 10. 코드 생성

### 10.1 build_runner 실행

```bash
# 특정 패키지
cd features/home
dart run build_runner build --delete-conflicting-outputs

# Melos로 전체
melos run build_runner
```

### 10.2 생성되는 파일

```
features/home/lib/data/
├── api/
│   ├── home_api.dart
│   └── home_api.g.dart      # Retrofit 생성
├── dto/
│   ├── home_dto.dart
│   └── home_dto.g.dart      # json_serializable 생성
```

## 11. Best Practices

### 11.1 DO (이렇게 하세요)

| 항목 | 설명 |
|------|------|
| API 인터페이스 분리 | Feature별로 API 클래스 분리 |
| DTO 필드 명명 | `fieldRename: FieldRename.snake` 사용 |
| 명시적 toJson | `explicitToJson: true` 설정 |
| 중첩 객체 | 별도 DTO 클래스로 정의 |
| Module로 등록 | Injectable @module에서 API 생성 |

### 11.2 DON'T (하지 마세요)

```dart
// ❌ 너무 많은 API를 하나의 클래스에
@RestApi()
abstract class ApiClient {
  // 100개의 엔드포인트... Feature별로 분리하세요
}

// ❌ dynamic 타입 사용
@GET('/api/data')
Future<dynamic> getData();  // 타입을 명시하세요

// ❌ DTO 없이 Map 사용
@POST('/api/items')
Future<Map<String, dynamic>> createItem(@Body() Map<String, dynamic> body);

// ❌ Response를 직접 도메인에서 사용
// DTO → Entity 변환 필수!
```

## 12. Dio vs Retrofit 선택 가이드

### 12.1 함께 사용

```dart
// Retrofit: 선언적 API 정의
@RestApi()
abstract class UserApi {
  factory UserApi(Dio dio, {String baseUrl}) = _UserApi;

  @GET('/users/{id}')
  Future<UserDto> getUser(@Path('id') String id);
}

// Dio: 동적/특수 케이스
class FileDownloader {
  final Dio _dio;

  FileDownloader(this._dio);

  Future<void> downloadFile(String url, String savePath) async {
    await _dio.download(
      url,
      savePath,
      onReceiveProgress: (received, total) {
        // 진행률 표시
      },
    );
  }
}
```

### 12.2 선택 기준

| 상황 | 선택 |
|------|------|
| 표준 REST API | Retrofit |
| 파일 다운로드 (진행률) | Dio |
| 동적 URL | Dio |
| WebSocket | Dio (별도 패키지) |
| GraphQL | Dio + graphql_flutter |

## 13. 보안

### 13.1 SSL Pinning

Retrofit은 내부적으로 Dio를 사용하므로, SSL Pinning 설정은 Dio Client에서 처리합니다.

```dart
// core/core_network/lib/src/injection.dart
@module
abstract class HomeApiModule {
  @lazySingleton
  HomeApi homeApi(Dio dio) => HomeApi(dio);  // SSL Pinning이 설정된 Dio 주입
}
```

**SSL Pinning 설정 방법:**
- Dio 가이드의 "4.6 SSL Pinning / Certificate Pinning" 섹션 참조
- DioClient에서 SSL Pinning 설정 후, Retrofit API에 주입하여 사용

**주의사항:**
- Retrofit API 생성 시 이미 SSL Pinning이 적용된 Dio 인스턴스를 전달
- 별도로 Retrofit에서 SSL 설정을 추가할 필요 없음
- 모든 보안 설정은 DI를 통해 주입되는 Dio에서 일괄 관리

## 14. 참고

- [Retrofit 공식 문서](https://pub.dev/packages/retrofit)
- [json_serializable 공식 문서](https://pub.dev/packages/json_serializable)
- Part 1: [Dio 가이드](./Networking_Dio.md) - SSL Pinning, 토큰 갱신 동시성 처리 포함

---

## 실습 과제

### 과제 1: Retrofit API 클라이언트 구현
User CRUD API를 Retrofit 어노테이션으로 정의하세요. @GET, @POST, @PUT, @DELETE 메서드와 json_serializable 모델을 조합하여 타입 안전한 API 계층을 구축하세요.

### 과제 2: 멀티파트 파일 업로드
프로필 이미지 업로드 API를 Retrofit의 @MultiPart와 @Part 어노테이션으로 구현하세요. 진행률 콜백과 에러 처리를 포함해 주세요.

## Self-Check

- [ ] Retrofit 어노테이션(@GET, @POST 등)으로 API 인터페이스를 정의할 수 있다
- [ ] json_serializable과 연동하여 요청/응답 직렬화를 자동화할 수 있다
- [ ] @Query, @Path, @Body, @Header 등 파라미터 어노테이션을 적절히 사용할 수 있다
- [ ] build_runner를 통한 코드 생성 워크플로우를 설정할 수 있다
