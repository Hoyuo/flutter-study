<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-01-27 | Updated: 2026-01-27 -->

# Networking

## Purpose

HTTP 통신 및 API 연동을 다루는 문서 모음입니다. Dio HTTP 클라이언트 설정과 Retrofit을 활용한 타입 세이프 API 서비스 정의 방법을 설명합니다.

## Key Files

| File | Description |
|------|-------------|
| `Networking_Dio.md` | Dio HTTP 클라이언트 설정, Interceptor 구성, 에러 처리, 토큰 갱신 |
| `Networking_Retrofit.md` | Retrofit 코드 생성, API 서비스 인터페이스 정의, 응답 매핑 |

## For AI Agents

### Working In This Directory

- Dio는 저수준 HTTP 설정, Retrofit은 고수준 API 정의
- 두 문서는 함께 사용되므로 연관성 유지
- 에러 처리는 `../system/ErrorHandling.md`와 연계

### Learning Path

1. `Networking_Dio.md` → HTTP 클라이언트 기초
2. `Networking_Retrofit.md` → API 서비스 정의

### Common Patterns

```dart
// Dio Interceptor
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }
}

// Retrofit API Service
@RestApi()
abstract class UserApi {
  factory UserApi(Dio dio) = _UserApi;

  @GET('/users/{id}')
  Future<UserResponse> getUser(@Path('id') String id);
}
```

## Dependencies

### Internal

- `../infrastructure/DI.md` - Dio 인스턴스 주입
- `../system/ErrorHandling.md` - API 에러 처리

### External

- `dio` - HTTP Client
- `retrofit` / `retrofit_generator` - API Code Generation
- `json_annotation` / `json_serializable` - JSON Serialization

<!-- MANUAL: -->
