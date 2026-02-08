<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-01-27 | Updated: 2026-02-07 -->

# Infrastructure

## Purpose

앱의 기반 인프라를 다루는 문서 모음입니다. 의존성 주입, 환경 설정, 로컬 저장소 등 앱 전반에서 사용되는 공통 인프라 구성 요소를 설명합니다.

## Key Files

| File | Description |
|------|-------------|
| `DI.md` | GetIt + Injectable을 활용한 의존성 주입 설정, 모듈 등록, 환경별 구성 |
| `Environment.md` | 환경 설정 관리, Flavor 구성, 빌드 변수, 다중 환경(dev/stg/prod) 지원 |
| `LocalStorage.md` | SharedPreferences, Hive, SecureStorage를 활용한 로컬 데이터 저장 |
| `CICD.md` | CI/CD 파이프라인 설정 (기본+심화 통합), GitHub Actions, Codemagic, Fastlane, Trunk-based, Canary Release, Shorebird OTA, Feature Flags |
| `StoreSubmission.md` | 앱스토어 제출 가이드, Play Store, App Store, 스크린샷, ASO |
| `Firebase.md` | Firebase 통합 (Auth, Firestore, Storage, FCM, Crashlytics, Analytics, Security Rules) |
| `FlutterMultiPlatform.md` | Web/Desktop 멀티플랫폼 확장, 플랫폼별 조건부 렌더링, Responsive Design |
| `PackageDevelopment.md` | Dart/Flutter 패키지 개발, Pub.dev 배포, 버전 관리, API 문서화 |
| `CachingStrategy.md` | 캐싱 전략, 메모리/디스크/네트워크 계층, HTTP 캐시, 이미지 캐싱 |
| `PlatformIntegration.md` | Platform Channel, Method Channel, FFI, Pigeon 코드 생성, 네이티브 통합 |
| `VersionMigration.md` | Flutter/Dart 버전 마이그레이션: FVM, dart fix, deprecated API 추적, 플랫폼별 체크리스트 |
| `DependencyManagement.md` | 의존성 관리: 버전 전략, pub outdated/upgrade, OSV Scanner, Renovate/Dependabot |
| `Troubleshooting.md` | 트러블슈팅: flutter doctor, Android/iOS 빌드 에러, 런타임 에러, 상태 관리 디버깅 |

## For AI Agents

### Working In This Directory

- DI 설정은 프로젝트 초기 설정 시 가장 먼저 구성
- Environment 설정은 CI/CD 파이프라인과 연동 고려
- LocalStorage는 민감 정보 저장 시 SecureStorage 사용 권장

### Learning Path

1. `DI.md` → 의존성 주입 기초 (앱 시작점)
2. `Environment.md` → 환경별 설정
3. `LocalStorage.md` → 로컬 데이터 관리

### Common Patterns

```dart
// GetIt 서비스 등록
@module
abstract class AppModule {
  @lazySingleton
  Dio get dio => Dio();

  @preResolve
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();
}

// Injectable 서비스
@injectable
class AuthService {
  final Dio _dio;
  AuthService(this._dio);
}
```

## Dependencies

### Internal

- `../core/` - Bloc/Freezed와 함께 사용
- `../networking/` - Dio 인스턴스 주입

### External

- `get_it` - Service Locator
- `injectable` / `injectable_generator` - Code Generation
- `shared_preferences` - Key-Value Storage
- `hive` / `hive_flutter` - NoSQL Database
- `flutter_secure_storage` - Encrypted Storage
- `firebase_core` / `firebase_auth` / `cloud_firestore` - Firebase Integration

<!-- MANUAL: -->
