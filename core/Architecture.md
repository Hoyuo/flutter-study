# Flutter Clean Architecture Guide

> 이 문서는 AI 에이전트(Claude, Copilot 등)가 프로젝트를 이해하고 작업할 때 반드시 참고해야 하는 가이드입니다.

## 1. 프로젝트 개요

- **플랫폼**: Flutter
- **아키텍처**: Clean Architecture + Feature-based Modularization
- **패키지 관리**: Melos Monorepo
- **Flutter 버전 관리**: FVM

## 2. 절대 규칙 (MUST)

### 2.1 1 클래스 1 파일 원칙

```
Dart에서는 1클래스 1파일이 기본입니다. (위젯 코드 제외)
```

- **DTO, Entity, UseCase, Repository, Mapper, Failure** 등은 반드시 개별 파일로 분리
- **위젯(Widget)만 예외**: 하나의 Screen 파일에 private 위젯(`_WidgetName`) 포함 가능
- **Freezed로 생성된 union type**은 하나의 파일에 있어도 됨

### 2.2 Bloc 생명주기 관리

```dart
// ✅ 올바른 패턴 - BlocProvider가 생명주기 관리
BlocProvider(
  create: (_) => HomeBloc(GetIt.I<GetHomeDataUseCase>()),
  child: const HomeScreen(),
)

// ❌ 잘못된 패턴 - Bloc을 GetIt에 등록하면 안 됨
@injectable  // Bloc에 사용 금지!
class HomeBloc extends Bloc { ... }
```

- **Bloc**: BlocProvider에서 직접 생성 (생명주기 자동 관리)
- **UseCase/Repository**: GetIt으로 관리 (singleton, 재사용)
- **이유**: BlocProvider가 close한 Bloc을 GetIt이 다시 반환하면 에러 발생

### 2.3 비즈니스 로직은 Bloc에

```dart
// ❌ Screen에 비즈니스 로직 금지
class MyScreen extends StatefulWidget {
  Future<void> _doSomething() async {
    await Future.delayed(Duration(seconds: 1));  // 비즈니스 로직
    await someUseCase.call();  // 직접 호출
  }
}

// ✅ Bloc에서 처리
class MyBloc extends Bloc<MyEvent, MyState> {
  Future<void> _onStarted(Emitter<MyState> emit) async {
    emit(const MyState.loading());
    await Future.delayed(Duration(seconds: 1));
    emit(const MyState.completed());
  }
}
```

## 3. 프로젝트 구조

```
{project}/
├── app/                    # 메인 앱 (라우터, DI 설정)
├── common/
│   ├── common_ui/          # 공통 UI 컴포넌트
│   ├── common_data/        # 공통 Data 레이어
│   └── common_auth/        # 공통 인증
├── core/
│   ├── core_network/       # 네트워크 (Dio)
│   └── core_utils/         # 유틸리티
└── features/
    ├── auth/               # 인증
    ├── home/               # 홈
    ├── intro/              # 인트로 (스플래시)
    ├── profile/            # 프로필
    ├── settings/           # 설정
    └── ...                 # 도메인별 feature 모듈
```

## 4. Feature 내부 구조

```
features/{feature_name}/lib/
├── {feature_name}.dart          # 메인 barrel 파일
├── data/
│   ├── data.dart                # Data 레이어 barrel
│   ├── datasources/
│   │   └── {feature}_remote_datasource.dart
│   ├── dto/
│   │   ├── {name}_dto.dart      # 1 DTO 1 파일
│   │   └── {name}_dto.g.dart    # json_serializable 생성
│   ├── mappers/
│   │   ├── {feature}_mapper.dart
│   │   └── {feature}_failure_mapper.dart
│   └── repositories/
│       └── {feature}_repository_impl.dart
├── domain/
│   ├── domain.dart              # Domain 레이어 barrel
│   ├── entities/
│   │   └── {name}.dart          # 1 Entity 1 파일
│   ├── failures/
│   │   └── {feature}_failure.dart
│   ├── repositories/
│   │   └── {feature}_repository.dart  # Interface
│   └── usecases/
│       └── {action}_{feature}_usecase.dart
├── presentation/
│   ├── presentation.dart        # Presentation 레이어 barrel
│   ├── bloc/
│   │   ├── {feature}_bloc.dart
│   │   ├── {feature}_event.dart
│   │   └── {feature}_state.dart
│   ├── screens/
│   │   └── {feature}_screen.dart
│   └── widgets/
│       └── {widget_name}.dart
└── src/
    ├── injection.dart
    └── injection.config.dart    # injectable 자동 생성
```

## 5. Barrel 파일 규칙

### 5.1 레이어별 Barrel

```dart
// data/data.dart
export 'datasources/home_remote_datasource.dart';
export 'dto/home_dto.dart';
export 'mappers/home_mapper.dart';
export 'repositories/home_repository_impl.dart';

// domain/domain.dart
export 'entities/home_data.dart';
export 'failures/home_failure.dart';
export 'repositories/home_repository.dart';
export 'usecases/get_home_data_usecase.dart';

// presentation/presentation.dart
export 'bloc/home_bloc.dart';
export 'bloc/home_event.dart';
export 'bloc/home_state.dart';
export 'screens/home_screen.dart';
```

### 5.2 Import 규칙

```dart
// ✅ 같은 feature 내에서는 barrel 파일 사용
import '../../domain/domain.dart';

// ✅ 같은 폴더 내 파일은 직접 import
import 'home_event.dart';
import 'home_state.dart';

// ✅ 외부 패키지는 직접 import
import 'package:flutter_bloc/flutter_bloc.dart';
```

## 6. 의존성 방향

```
┌─────────────────┐
│  Presentation   │ → Screen, Bloc, Widget
└────────┬────────┘
         │ depends on
         ▼
┌─────────────────┐
│     Domain      │ → Entity, UseCase, Repository(Interface), Failure
└────────┬────────┘
         │ implemented by
         ▼
┌─────────────────┐
│      Data       │ → DTO, DataSource, Mapper, Repository(Impl)
└─────────────────┘
```

- **Domain 레이어는 외부 의존성 없음** (순수 Dart)
- **Data → Domain**: Repository Interface 구현
- **Presentation → Domain**: UseCase 호출, Entity 사용

## 7. 라우팅 (Navigation)

### 7.1 라우팅은 App에서 중앙 관리

```
┌─────────────────────────────────┐
│              App                │  ← Composition Root
│  (Router, DI 설정, 모듈 조합)    │     모든 feature를 알고 조합
└──────────────┬──────────────────┘
               │ depends on
    ┌──────────┼──────────┬────────────┐
    ▼          ▼          ▼            ▼
┌───────┐ ┌───────┐ ┌─────────┐ ┌──────────┐
│ home  │ │search │ │ booking │ │vendor_   │
│       │ │       │ │         │ │detail    │
└───────┘ └───────┘ └─────────┘ └──────────┘
   (서로를 모름 - 완전히 독립적)
```

### 7.2 이유: Feature 모듈 간 순환 의존성 방지

```
만약 각 Feature에서 라우팅을 정의하면:

home → vendor_detail 이동 → home이 vendor_detail 의존
vendor_detail → booking 이동 → vendor_detail이 booking 의존
booking → home 돌아가기 → booking이 home 의존

→ 순환 의존성 발생!
```

### 7.3 App Router 패턴

```dart
// app/lib/src/router/app_router.dart
GoRouter createAppRouter(AppAuthNotifier authNotifier) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      // intro feature
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, _) => IntroScreen(onAuthCheck: authNotifier.checkAuthStatus),
      ),
      // auth feature
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _) => LoginScreen(...),
      ),
      // home feature
      GoRoute(
        path: AppRoutes.home,
        builder: (_, _) => const HomeScreen(),
      ),
      // vendor_detail feature
      GoRoute(
        path: '/vendor/:id',
        builder: (_, state) => VendorDetailScreen(
          vendorId: state.pathParameters['id']!,
        ),
      ),
    ],
  );
}
```

### 7.4 Feature 모듈의 역할

```dart
// ✅ Feature는 Screen만 export
// features/home/lib/home.dart
export 'presentation/presentation.dart';  // HomeScreen 포함

// ❌ Feature에서 다른 Feature로 직접 라우팅 금지
// features/home/lib/presentation/screens/home_screen.dart
import 'package:vendor_detail/vendor_detail.dart';  // 금지!
Navigator.push(context, VendorDetailScreen(...));   // 금지!

// ✅ go_router의 path로 이동 (Feature 간 의존성 없음)
context.push('/vendor/$vendorId');
```

### 7.5 다른 플랫폼과의 비교

| 플랫폼 | 패턴 | 위치 |
|--------|------|------|
| Android | Navigation Graph (nav_graph.xml) | app 모듈 |
| iOS | Coordinator Pattern | AppCoordinator |
| Flutter | GoRouter | app/lib/src/router/ |

**핵심**: 모든 플랫폼에서 Navigation은 최상위 레이어(App)에서 관리

## 8. Failure 패턴 (Feature별 Failure)

### 8.1 왜 공통 Failure가 아닌 Feature별 Failure인가?

```dart
// ❌ 잘못된 패턴 - 공통 Failure
// common/lib/failures/common_failure.dart
@freezed
class CommonFailure with _$CommonFailure {
  const factory CommonFailure.network() = _Network;
  const factory CommonFailure.server(String message) = _Server;
  const factory CommonFailure.unknown() = _Unknown;
  const factory CommonFailure.unauthorized() = _Unauthorized;
  const factory CommonFailure.cancelled() = _Cancelled;  // 특정 feature에만 필요
  const factory CommonFailure.invalidCredentials() = _InvalidCredentials;  // auth만 필요
}

// ✅ 올바른 패턴 - Feature별 Failure
// features/home/lib/domain/failures/home_failure.dart
@freezed
class HomeFailure with _$HomeFailure {
  const factory HomeFailure.network() = _Network;
  const factory HomeFailure.server(String message) = _Server;
  const factory HomeFailure.unknown() = _Unknown;
}

// features/auth/lib/domain/failures/auth_failure.dart
@freezed
class AuthFailure with _$AuthFailure {
  const factory AuthFailure.network() = _Network;
  const factory AuthFailure.server(String message) = _Server;
  const factory AuthFailure.unknown() = _Unknown;
  const factory AuthFailure.invalidCredentials() = _InvalidCredentials;  // auth 전용
  const factory AuthFailure.userNotFound() = _UserNotFound;  // auth 전용
}

// features/booking/lib/domain/failures/booking_failure.dart
@freezed
class BookingFailure with _$BookingFailure {
  const factory BookingFailure.network() = _Network;
  const factory BookingFailure.server(String message) = _Server;
  const factory BookingFailure.unknown() = _Unknown;
  const factory BookingFailure.cancelled() = _Cancelled;  // booking 전용
  const factory BookingFailure.slotUnavailable() = _SlotUnavailable;  // booking 전용
}
```

### 8.2 Feature별 Failure의 장점

| 관점 | 공통 Failure | Feature별 Failure |
|------|-------------|-------------------|
| **Domain 순수성** | 외부 의존성 발생 | ✅ 순수한 Domain 레이어 유지 |
| **Feature 독립성** | 다른 feature의 failure 케이스 포함 | ✅ 해당 feature에 필요한 것만 |
| **확장성** | 하나 추가 시 모든 feature 영향 | ✅ 개별 feature만 변경 |
| **타입 안전성** | 불필요한 케이스 처리 필요 | ✅ 필요한 케이스만 처리 |
| **테스트** | 모든 케이스 테스트 필요 | ✅ 해당 feature 케이스만 |

### 8.3 공통 부분 vs Feature 전용 부분

```
공통으로 보이는 부분:
├── network()       → 네트워크 오류 (인터넷 연결)
├── server(message) → 서버 오류 (5xx)
└── unknown()       → 알 수 없는 오류

Feature 전용 부분:
├── Auth: invalidCredentials, userNotFound, sessionExpired
├── Booking: cancelled, slotUnavailable, paymentFailed
├── Search: noResults, rateLimited
└── Profile: permissionDenied, dataNotFound
```

**중복이 있어도 Feature별로 정의하는 이유:**

1. **Domain 레이어 순수성**: Domain은 외부 의존성이 없어야 함
2. **Feature 독립성**: 각 feature는 독립적으로 배포/테스트 가능해야 함
3. **명확한 책임**: 해당 feature에서만 발생하는 에러를 명확히 정의
4. **Freezed when 패턴**: 필요한 케이스만 처리하여 코드 간결성 유지

### 8.4 Failure Mapper 패턴

```dart
// features/home/lib/data/mappers/home_failure_mapper.dart
class HomeFailureMapper {
  static HomeFailure fromDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
        return const HomeFailure.network();
      case DioExceptionType.badResponse:
        return HomeFailure.server(e.message ?? 'Server error');
      default:
        return const HomeFailure.unknown();
    }
  }
}

// features/auth/lib/data/mappers/auth_failure_mapper.dart
class AuthFailureMapper {
  static AuthFailure fromDioException(DioException e) {
    if (e.response?.statusCode == 401) {
      return const AuthFailure.invalidCredentials();
    }
    if (e.response?.statusCode == 404) {
      return const AuthFailure.userNotFound();
    }
    // 공통 처리
    switch (e.type) {
      case DioExceptionType.connectionError:
        return const AuthFailure.network();
      default:
        return const AuthFailure.unknown();
    }
  }
}
```

## 9. 네이밍 컨벤션

| 타입 | 파일명 | 클래스명 |
|------|--------|----------|
| DTO | `{name}_dto.dart` | `{Name}Dto` |
| Entity | `{name}.dart` | `{Name}` |
| UseCase | `{action}_{name}_usecase.dart` | `{Action}{Name}UseCase` |
| Repository Interface | `{feature}_repository.dart` | `{Feature}Repository` |
| Repository Impl | `{feature}_repository_impl.dart` | `{Feature}RepositoryImpl` |
| DataSource | `{feature}_remote_datasource.dart` | `{Feature}RemoteDataSource` |
| Mapper | `{feature}_mapper.dart` | `{Feature}Mapper` |
| Failure | `{feature}_failure.dart` | `{Feature}Failure` |
| Bloc | `{feature}_bloc.dart` | `{Feature}Bloc` |
| Event | `{feature}_event.dart` | `{Feature}Event` |
| State | `{feature}_state.dart` | `{Feature}State` |
| Screen | `{feature}_screen.dart` | `{Feature}Screen` |

## 10. 라이브러리 사용

| 용도 | 라이브러리 |
|------|-----------|
| 상태 관리 | flutter_bloc |
| DI | get_it + injectable |
| 불변 객체 | freezed + freezed_annotation |
| JSON 직렬화 | json_annotation + json_serializable |
| 함수형 | fpdart (Either, Option) |
| 라우팅 | go_router |
| 네트워크 | dio |
| 코드 생성 | build_runner |

## 11. Freezed 사용 패턴

### 11.1 Event

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'home_event.freezed.dart';

@freezed
class HomeEvent with _$HomeEvent {
  const factory HomeEvent.started() = _Started;
  const factory HomeEvent.refresh() = _Refresh;
  const factory HomeEvent.loadMore() = _LoadMore;
}
```

### 11.2 State

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'home_state.freezed.dart';

@freezed
class HomeState with _$HomeState {
  const factory HomeState.initial() = _Initial;
  const factory HomeState.loading() = _Loading;
  const factory HomeState.loaded(HomeData data) = _Loaded;
  const factory HomeState.error(String message) = _Error;
}
```

### 11.3 Failure

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'home_failure.freezed.dart';

@freezed
class HomeFailure with _$HomeFailure {
  const factory HomeFailure.network() = _Network;
  const factory HomeFailure.server(String message) = _Server;
  const factory HomeFailure.unknown() = _Unknown;
}
```

## 12. DTO 패턴 (json_serializable)

```dart
import 'package:json_annotation/json_annotation.dart';
part 'home_dto.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class HomeDto {
  final String id;
  final String title;
  final DateTime createdAt;

  HomeDto({
    required this.id,
    required this.title,
    required this.createdAt,
  });

  factory HomeDto.fromJson(Map<String, dynamic> json) => _$HomeDtoFromJson(json);
  Map<String, dynamic> toJson() => _$HomeDtoToJson(this);
}
```

## 13. UseCase 패턴

```dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetHomeDataUseCase {
  final HomeRepository _repository;

  GetHomeDataUseCase(this._repository);

  Future<Either<HomeFailure, HomeData>> call() {
    return _repository.getHomeData();
  }
}
```

## 14. Repository 패턴

### Interface (Domain)

```dart
import 'package:fpdart/fpdart.dart';

abstract class HomeRepository {
  Future<Either<HomeFailure, HomeData>> getHomeData();
}
```

### Implementation (Data)

```dart
import 'package:fpdart/fpdart.dart';
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
      return Left(HomeFailureMapper.fromDioException(e));
    }
  }
}
```

## 15. Bloc 패턴

```dart
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetHomeDataUseCase _getHomeDataUseCase;

  HomeBloc(this._getHomeDataUseCase) : super(const HomeState.initial()) {
    on<HomeEvent>(_onEvent);
  }

  Future<void> _onEvent(HomeEvent event, Emitter<HomeState> emit) async {
    await event.when(
      started: () => _onStarted(emit),
      refresh: () => _onRefresh(emit),
    );
  }

  Future<void> _onStarted(Emitter<HomeState> emit) async {
    emit(const HomeState.loading());
    final result = await _getHomeDataUseCase();
    result.fold(
      (failure) => emit(HomeState.error(failure.message)),
      (data) => emit(HomeState.loaded(data)),
    );
  }
}
```

## 16. Screen 패턴

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeBloc(
        GetIt.I<GetHomeDataUseCase>(),
      )..add(const HomeEvent.started()),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        return state.when(
          initial: () => const SizedBox.shrink(),
          loading: () => const LoadingIndicator(),
          loaded: (data) => _buildContent(data),
          error: (message) => ErrorView(message: message),
        );
      },
    );
  }
}
```

## 17. 코드 생성 명령어

```bash
# 특정 feature에서 build_runner 실행
cd features/{feature_name}
fvm flutter pub run build_runner build --delete-conflicting-outputs

# 전체 프로젝트 분석
melos run analyze

# 전체 프로젝트 build_runner (melos에 설정된 경우)
melos run build_runner
```

## 18. 새 Feature 생성 체크리스트

1. [ ] `features/{feature_name}/` 폴더 생성
2. [ ] `pubspec.yaml` 작성
3. [ ] 레이어 폴더 구조 생성 (data, domain, presentation, src)
4. [ ] Domain 레이어 먼저 작성 (Entity, Failure, Repository Interface, UseCase)
5. [ ] Data 레이어 작성 (DTO, DataSource, Mapper, Repository Impl)
6. [ ] Presentation 레이어 작성 (Bloc, Event, State, Screen)
7. [ ] Barrel 파일 작성 (data.dart, domain.dart, presentation.dart, {feature}.dart)
8. [ ] injection.dart 설정
9. [ ] build_runner 실행
10. [ ] melos bootstrap 실행
11. [ ] analyze 통과 확인

## 19. 자주 하는 실수

### ❌ 여러 클래스를 한 파일에

```dart
// ❌ 금지
// user_dto.dart
class UserDto { ... }
class UserResponseDto { ... }  // 별도 파일로 분리 필요
```

### ❌ Bloc을 Injectable로 등록

```dart
// ❌ 금지 - 생명주기 문제 발생
@injectable
class HomeBloc extends Bloc { ... }
```

### ❌ Screen에서 비즈니스 로직

```dart
// ❌ 금지
class MyScreen extends StatefulWidget {
  void _onTap() async {
    await Future.delayed(Duration(seconds: 1));  // Bloc으로 이동
  }
}
```

### ❌ 개별 파일 import (같은 feature 내)

```dart
// ❌ 비권장
import '../../domain/entities/home_data.dart';
import '../../domain/failures/home_failure.dart';

// ✅ 권장
import '../../domain/domain.dart';
```

### ❌ 공통 Failure 사용

```dart
// ❌ 금지 - Domain 순수성 및 Feature 독립성 위반
// common/lib/failures/common_failure.dart
class CommonFailure { ... }

// ✅ 권장 - Feature별 Failure 정의
// features/home/lib/domain/failures/home_failure.dart
class HomeFailure { ... }
```

## 20. 참고 사항

- **언어**: 코드 주석은 한글 가능, 변수/함수/클래스명은 영문
- **분석 도구**: `melos run analyze`로 전체 프로젝트 린트 체크
- **테스트**: 각 feature의 `test/` 폴더에 작성
