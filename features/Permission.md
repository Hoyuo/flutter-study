# Flutter 권한 처리 가이드 (permission_handler)

> **난이도**: 중급 | **카테고리**: features
> **선행 학습**: [Architecture](../core/Architecture.md) | **예상 학습 시간**: 1h

## 학습 목표

이 문서를 학습하면 다음을 할 수 있습니다:

1. permission_handler를 사용하여 iOS/Android 런타임 권한을 통합적으로 처리할 수 있다
2. PermissionStatus 상태별(denied, granted, permanentlyDenied, limited) 적절한 UX 흐름을 구현할 수 있다
3. Android 13+ 저장소 권한 변경(photos/videos/audio)에 대응하는 마이그레이션을 수행할 수 있다
4. Pre-permission Rationale 다이얼로그로 권한 승인율을 높이는 패턴을 적용할 수 있다
5. PermissionService 추상화와 Bloc을 연동한 Clean Architecture 기반 권한 관리 시스템을 구축할 수 있다

## 개요

permission_handler는 Flutter에서 iOS와 Android의 런타임 권한을 통합적으로 처리할 수 있는 패키지입니다. 카메라, 위치, 알림 등 다양한 권한을 일관된 API로 관리할 수 있습니다.

## 설치 및 설정

### 의존성 추가

```yaml
# pubspec.yaml
dependencies:
  permission_handler: ^12.0.1
  device_info_plus: ^12.3.0  # Android SDK 버전 확인용 (저장소 권한 처리 시 필요)
```

### Migration Notes (v12 → v13)

**Breaking Changes:**
- **Android 15 Support**: `compileSdkVersion` 35 이상 필요 (Android 15 대응)
  ```kotlin
  // android/app/build.gradle.kts
  android {
      compileSdk = 35
  }
  ```
- **iOS Minimum Version**: iOS deployment target 12.0 이상 필수
  ```ruby
  # ios/Podfile
  platform :ios, '12.0'
  ```
- **Android Plugin Update**: `permission_handler_android` 13.0.0 이상 필요
- **Permission.storage 완전 제거**: Android 13+ 에서 `Permission.storage` 사용 불가
  - 대신 세분화된 권한 사용 필수:
    - `Permission.photos` - 이미지/사진 접근
    - `Permission.videos` - 비디오 접근
    - `Permission.audio` - 오디오 파일 접근
    - `Permission.manageExternalStorage` - 전체 저장소 접근 (특수 용도)

**마이그레이션 가이드:**

1. **저장소 권한 업데이트**
```dart
// ❌ 기존 (v12)
await Permission.storage.request();

// ✅ 새로운 방식 (v13)
if (Platform.isAndroid) {
  final androidInfo = await DeviceInfoPlugin().androidInfo;
  if (androidInfo.version.sdkInt >= 33) {
    // Android 13+
    await [
      Permission.photos,
      Permission.videos,
      Permission.audio,
    ].request();
  } else {
    // Android 12 이하
    await Permission.storage.request();
  }
} else {
  await Permission.photos.request();
}
```

2. **Android Manifest 업데이트**
```xml
<!-- Android 12 이하용 (호환성 유지) -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
                 android:maxSdkVersion="32"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
                 android:maxSdkVersion="32"/>

<!-- Android 13+ 필수 -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO"/>
```

**주의사항:**
- Android 13+ 기기에서 `Permission.storage` 사용 시 런타임 에러 발생 가능
- iOS는 기존 `Permission.photos` 사용 (변경 없음)
- 전체 저장소 접근이 필요한 경우 `Permission.manageExternalStorage` 사용 (Play Store 승인 필요)

### Migration Notes (v11 → v12)

**Breaking Changes:**
- **New Permission Request Flow**: Permissions now require explicit context about usage. Some platforms may show additional prompts.
- **Android 14+ Support**: Added support for new Android 14 permissions (e.g., `Permission.photos`, `Permission.videos`, `Permission.audio` replacing `Permission.storage`).
- **iOS Precise Location**: `Permission.locationWhenInUse` now supports requesting precise vs. approximate location.
- **Notification Permission Changes**: `Permission.notification` behavior updated for iOS 16+ provisional notifications.

**Deprecated APIs:**
- `Permission.storage` is deprecated on Android 13+. Use `Permission.photos`, `Permission.videos`, or `Permission.audio` instead.
- Direct `openAppSettings()` calls should now check permission status first to avoid unnecessary navigations.

**New Features:**
- Support for Android 14 partial photo/video access
- Enhanced permission status detection for restricted modes
- Better handling of provisional authorization on iOS

### iOS 설정

```xml
<!-- ios/Runner/Info.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <!-- 카메라 -->
  <key>NSCameraUsageDescription</key>
  <string>프로필 사진 촬영을 위해 카메라 접근이 필요합니다.</string>

  <!-- 사진 라이브러리 -->
  <key>NSPhotoLibraryUsageDescription</key>
  <string>프로필 사진 선택을 위해 사진 라이브러리 접근이 필요합니다.</string>

  <!-- 위치 (사용 중) -->
  <key>NSLocationWhenInUseUsageDescription</key>
  <string>주변 매장 검색을 위해 위치 정보가 필요합니다.</string>

  <!-- 위치 (항상) -->
  <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
  <string>배송 추적을 위해 백그라운드 위치 접근이 필요합니다.</string>

  <!-- 마이크 -->
  <key>NSMicrophoneUsageDescription</key>
  <string>음성 메시지 녹음을 위해 마이크 접근이 필요합니다.</string>

  <!-- 연락처 -->
  <key>NSContactsUsageDescription</key>
  <string>친구 초대를 위해 연락처 접근이 필요합니다.</string>

  <!-- 알림 -->
  <!-- 알림은 Info.plist 설정 불필요, 코드로 요청 -->
</dict>
</plist>
```

### iOS Podfile 설정

**v13 요구사항:**
```ruby
# ios/Podfile
platform :ios, '12.0'  # v13부터 최소 12.0 이상 필수
```

```ruby
# ios/Podfile
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)

    target.build_configurations.each do |config|
      # 사용하지 않는 권한 비활성화 (앱 크기 최적화)
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        # 사용하는 권한만 1로 설정
        'PERMISSION_CAMERA=1',
        'PERMISSION_PHOTOS=1',
        'PERMISSION_LOCATION=1',
        'PERMISSION_NOTIFICATIONS=1',
        'PERMISSION_MICROPHONE=1',
        'PERMISSION_CONTACTS=1',
        # 사용하지 않는 권한은 0
        'PERMISSION_BLUETOOTH=0',
        'PERMISSION_CALENDARS=0',
        'PERMISSION_REMINDERS=0',
        'PERMISSION_SPEECH_RECOGNIZER=0',
        'PERMISSION_MEDIA_LIBRARY=0',
        'PERMISSION_SENSORS=0',
      ]
    end
  end
end
```

### Android 설정

**v13 요구사항:**
```kotlin
// android/app/build.gradle.kts
android {
    compileSdk = 35  // v13부터 필수: Android 15 대응

    defaultConfig {
        minSdk = 21
        targetSdk = 35  // 최신 targetSdk 권장
    }
}
```

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

  <!-- 카메라 -->
  <uses-permission android:name="android.permission.CAMERA"/>

  <!-- 저장소 (Android 12 이하) -->
  <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
  <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>

  <!-- 미디어 (Android 13+) -->
  <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
  <uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>
  <uses-permission android:name="android.permission.READ_MEDIA_AUDIO"/>

  <!-- 위치 -->
  <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
  <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
  <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>

  <!-- 마이크 -->
  <uses-permission android:name="android.permission.RECORD_AUDIO"/>

  <!-- 연락처 -->
  <uses-permission android:name="android.permission.READ_CONTACTS"/>

  <!-- 알림 (Android 13+) -->
  <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

  <application>
    ...
  </application>
</manifest>
```

## 권한 상태

### PermissionStatus 종류

```dart
enum PermissionStatus {
  /// 권한이 거부됨 (요청 가능)
  denied,

  /// 권한이 허용됨
  granted,

  /// 권한 요청이 제한됨 (iOS only: 보호자 제한 등)
  restricted,

  /// 권한이 제한적으로 허용됨 (iOS 14+ 사진 라이브러리)
  limited,

  /// 권한이 영구적으로 거부됨 (설정에서만 변경 가능)
  permanentlyDenied,

  /// 권한을 임시로 허용함 (iOS 15+ 위치)
  provisional,
}
```

### 상태 확인 헬퍼

```dart
extension PermissionStatusX on PermissionStatus {
  /// 권한이 허용되었는지
  bool get isGranted => this == PermissionStatus.granted;

  /// 권한이 거부되었는지 (다시 요청 가능)
  bool get isDenied => this == PermissionStatus.denied;

  /// 영구 거부되었는지 (설정으로 이동 필요)
  bool get isPermanentlyDenied => this == PermissionStatus.permanentlyDenied;

  /// 제한되었는지 (iOS 보호자 제한)
  bool get isRestricted => this == PermissionStatus.restricted;

  /// 제한적으로 허용되었는지 (iOS 14+ 사진)
  bool get isLimited => this == PermissionStatus.limited;

  /// 사용 가능한지 (granted 또는 limited)
  bool get isAvailable => isGranted || isLimited;
}
```

## 기본 사용법

### 단일 권한 요청

```dart
import 'package:permission_handler/permission_handler.dart';

// 권한 상태 확인
final status = await Permission.camera.status;

if (status.isGranted) {
  // 카메라 사용
  openCamera();
} else if (status.isDenied) {
  // 권한 요청
  final result = await Permission.camera.request();
  if (result.isGranted) {
    openCamera();
  }
} else if (status.isPermanentlyDenied) {
  // 설정으로 이동 안내
  await openAppSettings();
}
```

### 여러 권한 동시 요청

```dart
// 여러 권한 상태 확인
final statuses = await [
  Permission.camera,
  Permission.microphone,
  Permission.photos,  // v13: storage 대신 photos 사용
].request();

final cameraGranted = statuses[Permission.camera]?.isGranted ?? false;
final micGranted = statuses[Permission.microphone]?.isGranted ?? false;
final photosGranted = statuses[Permission.photos]?.isGranted ?? false;

if (cameraGranted && micGranted && photosGranted) {
  // 모든 권한 허용됨
  startVideoRecording();
}
```

## Permission Service 구현

### 추상 인터페이스

```dart
// lib/core/permission/permission_service.dart
import 'package:permission_handler/permission_handler.dart';

abstract class PermissionService {
  /// 권한 상태 확인
  Future<PermissionStatus> checkStatus(Permission permission);

  /// 권한 요청
  Future<PermissionStatus> request(Permission permission);

  /// 여러 권한 요청
  Future<Map<Permission, PermissionStatus>> requestMultiple(
    List<Permission> permissions,
  );

  /// 설정 앱 열기
  Future<bool> openSettings();

  /// 권한이 영구 거부되었는지 확인
  Future<bool> isPermanentlyDenied(Permission permission);
}
```

### 구현체

```dart
// lib/core/permission/permission_service_impl.dart
import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart';

import 'permission_service.dart';

@LazySingleton(as: PermissionService)
class PermissionServiceImpl implements PermissionService {
  @override
  Future<PermissionStatus> checkStatus(Permission permission) async {
    return permission.status;
  }

  @override
  Future<PermissionStatus> request(Permission permission) async {
    // 이미 허용된 경우 바로 반환
    final status = await permission.status;
    if (status.isGranted || status.isLimited) {
      return status;
    }

    // 권한 요청
    return permission.request();
  }

  @override
  Future<Map<Permission, PermissionStatus>> requestMultiple(
    List<Permission> permissions,
  ) async {
    return permissions.request();
  }

  @override
  Future<bool> openSettings() async {
    return openAppSettings();
  }

  @override
  Future<bool> isPermanentlyDenied(Permission permission) async {
    return permission.isPermanentlyDenied;
  }
}
```

## UseCase 패턴

### 권한 요청 UseCase

```dart
// lib/features/permission/domain/usecases/request_permission_usecase.dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/permission/permission_service.dart';

@injectable
class RequestPermissionUseCase {
  final PermissionService _permissionService;

  RequestPermissionUseCase(this._permissionService);

  Future<Either<Failure, PermissionStatus>> call(Permission permission) async {
    try {
      final status = await _permissionService.request(permission);
      return Right(status);
    } catch (e) {
      return Left(Failure.unknown(message: e.toString()));
    }
  }
}
```

### 카메라 권한 요청 UseCase (특화)

```dart
// lib/features/permission/domain/usecases/request_camera_permission_usecase.dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/permission/permission_service.dart';

sealed class CameraPermissionResult {
  const CameraPermissionResult();
}

class CameraPermissionGranted extends CameraPermissionResult {
  const CameraPermissionGranted();
}

class CameraPermissionDenied extends CameraPermissionResult {
  const CameraPermissionDenied();
}

class CameraPermissionPermanentlyDenied extends CameraPermissionResult {
  const CameraPermissionPermanentlyDenied();
}

@injectable
class RequestCameraPermissionUseCase {
  final PermissionService _permissionService;

  RequestCameraPermissionUseCase(this._permissionService);

  Future<Either<Failure, CameraPermissionResult>> call() async {
    try {
      final status = await _permissionService.request(Permission.camera);

      if (status.isGranted) {
        return const Right(CameraPermissionGranted());
      } else if (status.isPermanentlyDenied) {
        return const Right(CameraPermissionPermanentlyDenied());
      } else {
        return const Right(CameraPermissionDenied());
      }
    } catch (e) {
      return Left(Failure.unknown(message: e.toString()));
    }
  }
}
```

## Bloc 통합

### Permission Bloc

```dart
// lib/features/permission/presentation/bloc/permission_event.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:permission_handler/permission_handler.dart';

part 'permission_event.freezed.dart';

@freezed
class PermissionEvent with _$PermissionEvent {
  const factory PermissionEvent.requested(Permission permission) = _Requested;
  const factory PermissionEvent.multipleRequested(List<Permission> permissions) = _MultipleRequested;
  const factory PermissionEvent.settingsOpened() = _SettingsOpened;
}
```

```dart
// lib/features/permission/presentation/bloc/permission_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:permission_handler/permission_handler.dart';

part 'permission_state.freezed.dart';

@freezed
class PermissionState with _$PermissionState {
  const factory PermissionState({
    required Map<Permission, PermissionStatus> statuses,
    required bool isLoading,
    String? error,
  }) = _PermissionState;

  factory PermissionState.initial() => const PermissionState(
        statuses: {},
        isLoading: false,
      );
}

extension PermissionStateX on PermissionState {
  bool isGranted(Permission permission) =>
      statuses[permission]?.isGranted ?? false;

  bool isPermanentlyDenied(Permission permission) =>
      statuses[permission]?.isPermanentlyDenied ?? false;
}
```

```dart
// lib/features/permission/presentation/bloc/permission_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../domain/usecases/request_permission_usecase.dart';
import '../../../../core/permission/permission_service.dart';
import 'permission_event.dart';
import 'permission_state.dart';

class PermissionBloc extends Bloc<PermissionEvent, PermissionState> {
  final RequestPermissionUseCase _requestPermissionUseCase;
  final PermissionService _permissionService;

  PermissionBloc({
    required RequestPermissionUseCase requestPermissionUseCase,
    required PermissionService permissionService,
  })  : _requestPermissionUseCase = requestPermissionUseCase,
        _permissionService = permissionService,
        super(PermissionState.initial()) {
    on<PermissionEvent>((event, emit) async {
      await event.when(
        requested: (permission) => _onRequested(permission, emit),
        multipleRequested: (permissions) => _onMultipleRequested(permissions, emit),
        settingsOpened: () => _onSettingsOpened(emit),
      );
    });
  }

  Future<void> _onRequested(
    Permission permission,
    Emitter<PermissionState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    final result = await _requestPermissionUseCase(permission);

    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        error: failure.message,
      )),
      (status) => emit(state.copyWith(
        isLoading: false,
        statuses: {...state.statuses, permission: status},
      )),
    );
  }

  Future<void> _onMultipleRequested(
    List<Permission> permissions,
    Emitter<PermissionState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    final statuses = await _permissionService.requestMultiple(permissions);

    emit(state.copyWith(
      isLoading: false,
      statuses: {...state.statuses, ...statuses},
    ));
  }

  Future<void> _onSettingsOpened(Emitter<PermissionState> emit) async {
    await _permissionService.openSettings();
  }
}
```

## UI 패턴

### 권한 요청 다이얼로그

```dart
// lib/features/permission/presentation/widgets/permission_dialog.dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionDialog extends StatelessWidget {
  final Permission permission;
  final String title;
  final String description;
  final VoidCallback onRequest;
  final VoidCallback? onCancel;
  final bool isPermanentlyDenied;
  final VoidCallback? onOpenSettings;

  const PermissionDialog({
    super.key,
    required this.permission,
    required this.title,
    required this.description,
    required this.onRequest,
    this.onCancel,
    this.isPermanentlyDenied = false,
    this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(description),
      actions: [
        TextButton(
          onPressed: onCancel ?? () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: isPermanentlyDenied ? onOpenSettings : onRequest,
          child: Text(isPermanentlyDenied ? '설정으로 이동' : '허용하기'),
        ),
      ],
    );
  }
}
```

### 권한 요청 화면

```dart
// lib/features/permission/presentation/pages/permission_request_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../bloc/permission_bloc.dart';
import '../bloc/permission_event.dart';
import '../bloc/permission_state.dart';

class PermissionRequestPage extends StatelessWidget {
  const PermissionRequestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 80, color: Colors.blue),
              const SizedBox(height: 32),
              const Text(
                '앱 사용을 위해\n권한이 필요합니다',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 48),
              _PermissionItem(
                icon: Icons.camera_alt,
                title: '카메라',
                description: '프로필 사진 촬영',
                permission: Permission.camera,
              ),
              const SizedBox(height: 16),
              _PermissionItem(
                icon: Icons.photo_library,
                title: '사진',
                description: '사진 선택 및 저장',
                permission: Permission.photos,
              ),
              const SizedBox(height: 16),
              _PermissionItem(
                icon: Icons.location_on,
                title: '위치',
                description: '주변 매장 검색',
                permission: Permission.location,
              ),
              const SizedBox(height: 16),
              _PermissionItem(
                icon: Icons.notifications,
                title: '알림',
                description: '주문 상태 알림',
                permission: Permission.notification,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.read<PermissionBloc>().add(
                          const PermissionEvent.multipleRequested([
                            Permission.camera,
                            Permission.photos,
                            Permission.location,
                            Permission.notification,
                          ]),
                        );
                  },
                  child: const Text('모든 권한 허용하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Permission permission;

  const _PermissionItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.permission,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PermissionBloc, PermissionState>(
      builder: (context, state) {
        final isGranted = state.isGranted(permission);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isGranted ? Colors.green.shade50 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isGranted ? Colors.green : Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: isGranted ? Colors.green : Colors.grey),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isGranted)
                const Icon(Icons.check_circle, color: Colors.green)
              else
                TextButton(
                  onPressed: () {
                    context.read<PermissionBloc>().add(
                          PermissionEvent.requested(permission),
                        );
                  },
                  child: const Text('허용'),
                ),
            ],
          ),
        );
      },
    );
  }
}
```

### 권한 필요시 요청 위젯

```dart
// lib/features/permission/presentation/widgets/permission_required_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../bloc/permission_bloc.dart';
import '../bloc/permission_event.dart';
import '../bloc/permission_state.dart';
import 'permission_dialog.dart';

class PermissionRequiredButton extends StatelessWidget {
  final Permission permission;
  final String permissionTitle;
  final String permissionDescription;
  final Widget child;
  final VoidCallback onPermissionGranted;

  const PermissionRequiredButton({
    super.key,
    required this.permission,
    required this.permissionTitle,
    required this.permissionDescription,
    required this.child,
    required this.onPermissionGranted,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PermissionBloc, PermissionState>(
      listenWhen: (prev, curr) =>
          prev.statuses[permission] != curr.statuses[permission],
      listener: (context, state) {
        if (state.isGranted(permission)) {
          onPermissionGranted();
        }
      },
      builder: (context, state) {
        return GestureDetector(
          onTap: () async {
            final status = await permission.status;

            if (status.isGranted) {
              onPermissionGranted();
            } else if (status.isPermanentlyDenied) {
              _showPermanentlyDeniedDialog(context);
            } else {
              _showPermissionDialog(context, status);
            }
          },
          child: child,
        );
      },
    );
  }

  void _showPermissionDialog(BuildContext context, PermissionStatus status) {
    showDialog(
      context: context,
      builder: (_) => PermissionDialog(
        permission: permission,
        title: permissionTitle,
        description: permissionDescription,
        onRequest: () {
          Navigator.pop(context);
          context.read<PermissionBloc>().add(
                PermissionEvent.requested(permission),
              );
        },
      ),
    );
  }

  void _showPermanentlyDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => PermissionDialog(
        permission: permission,
        title: '$permissionTitle 권한 필요',
        description: '설정에서 $permissionTitle 권한을 허용해주세요.',
        isPermanentlyDenied: true,
        onRequest: () {},
        onOpenSettings: () {
          Navigator.pop(context);
          context.read<PermissionBloc>().add(
                const PermissionEvent.settingsOpened(),
              );
        },
      ),
    );
  }
}
```

## 권한별 처리 패턴

### 저장소/미디어 권한 (v13 중요 변경사항)

**Android 13+ 저장소 권한 처리:**

```dart
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

Future<bool> requestStoragePermission() async {
  if (Platform.isAndroid) {
    final androidInfo = await DeviceInfoPlugin().androidInfo;

    if (androidInfo.version.sdkInt >= 33) {
      // Android 13+ (API 33+): 세분화된 미디어 권한 사용
      final statuses = await [
        Permission.photos,      // 이미지 접근
        Permission.videos,      // 비디오 접근
        Permission.audio,       // 오디오 파일 접근
      ].request();

      // 필요한 권한이 모두 허용되었는지 확인
      return statuses.values.every((status) => status.isGranted);

    } else {
      // Android 12 이하: 기존 storage 권한 사용
      final status = await Permission.storage.request();
      return status.isGranted;
    }
  } else {
    // iOS: photos 권한 사용
    final status = await Permission.photos.request();
    return status.isGranted || status.isLimited;
  }
}

// 특정 미디어 타입만 필요한 경우
Future<bool> requestPhotoOnlyPermission() async {
  if (Platform.isAndroid) {
    final androidInfo = await DeviceInfoPlugin().androidInfo;

    if (androidInfo.version.sdkInt >= 33) {
      // Android 13+: 사진만 요청
      final status = await Permission.photos.request();
      return status.isGranted;
    } else {
      // Android 12 이하
      final status = await Permission.storage.request();
      return status.isGranted;
    }
  } else {
    final status = await Permission.photos.request();
    return status.isGranted || status.isLimited;
  }
}

// 전체 저장소 접근이 필요한 경우 (파일 관리자 앱 등)
Future<bool> requestManageExternalStorage() async {
  if (Platform.isAndroid) {
    final androidInfo = await DeviceInfoPlugin().androidInfo;

    if (androidInfo.version.sdkInt >= 30) {
      // Android 11+ (API 30+): MANAGE_EXTERNAL_STORAGE 필요
      // 주의: Play Store 승인 필요!
      final status = await Permission.manageExternalStorage.request();
      return status.isGranted;
    } else {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
  }
  return false;
}
```

**권한별 사용 사례:**

| 권한 | Android 버전 | 사용 목적 | Play Store 승인 |
|------|-------------|----------|----------------|
| `Permission.photos` | 13+ (API 33+) | 이미지/사진 읽기 | 불필요 |
| `Permission.videos` | 13+ (API 33+) | 비디오 파일 읽기 | 불필요 |
| `Permission.audio` | 13+ (API 33+) | 오디오 파일 읽기 | 불필요 |
| `Permission.storage` | 12 이하 (API ≤32) | 전체 외부 저장소 | 불필요 |
| `Permission.manageExternalStorage` | 11+ (API 30+) | 전체 파일 시스템 접근 | **필수** |

**중요 참고사항:**
- `Permission.storage`는 Android 13+에서 deprecated되어 작동하지 않음
- Android 13+에서는 반드시 세분화된 미디어 권한(`photos`, `videos`, `audio`) 사용
- `manageExternalStorage`는 파일 관리자, 백업 앱 등 특수한 경우에만 사용
- Play Store에서 `manageExternalStorage` 사용 시 별도 승인 절차 필요

### 위치 권한

```dart
Future<void> requestLocationPermission() async {
  // 먼저 위치 서비스 활성화 확인
  final serviceEnabled = await Permission.location.serviceStatus.isEnabled;
  if (!serviceEnabled) {
    // 위치 서비스 활성화 요청
    showLocationServiceDialog();
    return;
  }

  // 권한 요청
  var status = await Permission.location.request();

  if (status.isGranted) {
    // 위치 정보 사용
  } else if (status.isPermanentlyDenied) {
    // 설정으로 이동 안내
    openAppSettings();
  }
}

// 백그라운드 위치 (추가 권한)
Future<void> requestBackgroundLocation() async {
  // 먼저 foreground 위치 권한 필요
  final foregroundStatus = await Permission.location.status;
  if (!foregroundStatus.isGranted) {
    await Permission.location.request();
    return;
  }

  // 백그라운드 위치 권한 요청
  final status = await Permission.locationAlways.request();
  if (status.isGranted) {
    // 백그라운드 위치 추적 가능
  }
}
```

### 알림 권한 (iOS/Android 13+)

```dart
Future<void> requestNotificationPermission() async {
  final status = await Permission.notification.status;

  if (status.isDenied) {
    // 권한 요청
    final result = await Permission.notification.request();
    if (result.isGranted) {
      // 알림 설정 완료
    }
  } else if (status.isPermanentlyDenied) {
    // 설정으로 이동
    openAppSettings();
  }
}
```

### 사진 라이브러리 (iOS 14+ Limited Access)

```dart
Future<void> requestPhotoPermission() async {
  final status = await Permission.photos.request();

  if (status.isGranted) {
    // 전체 사진 접근 가능
    openPhotoLibrary();
  } else if (status.isLimited) {
    // 제한된 사진만 접근 가능 (iOS 14+)
    openPhotoLibrary();  // 선택된 사진만 표시됨
    showLimitedAccessBanner();  // 사용자에게 안내
  } else if (status.isPermanentlyDenied) {
    openAppSettings();
  }
}

void showLimitedAccessBanner() {
  // "선택한 사진만 볼 수 있습니다. 더 많은 사진에 접근하려면 설정을 변경하세요."
}
```

## 10. Pre-permission Rationale (권한 요청 전 설명)

### 10.1 왜 필요한가?

시스템 권한 팝업 전에 사용자에게 이유를 설명하면 **권한 승인율이 30% 이상 향상**됩니다.

### 10.2 구현 패턴

```dart
// lib/core/permission/permission_rationale_dialog.dart
class PermissionRationaleDialog extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onContinue;
  final VoidCallback onCancel;

  const PermissionRationaleDialog({
    required this.title,
    required this.description,
    required this.icon,
    required this.onContinue,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(icon, size: 48, color: Theme.of(context).primaryColor),
      title: Text(title),
      content: Text(description),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('나중에'),
        ),
        ElevatedButton(
          onPressed: onContinue,
          child: const Text('계속'),
        ),
      ],
    );
  }
}

// 사용 예시
Future<bool> requestCameraWithRationale(BuildContext context) async {
  // 이미 승인된 경우 바로 true 반환
  if (await Permission.camera.isGranted) return true;

  // 설명 다이얼로그 표시
  final shouldContinue = await showDialog<bool>(
    context: context,
    builder: (_) => PermissionRationaleDialog(
      title: '카메라 접근 필요',
      description: '사진 일기를 작성하려면 카메라 접근이 필요합니다.\n'
                   '촬영된 사진은 기기에만 저장되며 서버로 전송되지 않습니다.',
      icon: Icons.camera_alt,
      onContinue: () => Navigator.pop(context, true),
      onCancel: () => Navigator.pop(context, false),
    ),
  );

  if (shouldContinue != true) return false;

  // 시스템 권한 요청
  final status = await Permission.camera.request();
  return status.isGranted;
}
```

## 11. iOS App Tracking Transparency (ATT)

### 11.1 ATT란?

iOS 14.5+에서 광고 추적(IDFA)을 위해 **반드시 사용자 동의**가 필요합니다.
App Store 심사 시 ATT 없이 IDFA 접근 시 **리젝** 됩니다.

### 11.2 설정

```xml
<!-- ios/Runner/Info.plist -->
<key>NSUserTrackingUsageDescription</key>
<string>맞춤형 광고와 앱 사용 분석을 위해 활동 추적 권한이 필요합니다.</string>
```

### 11.3 구현

```dart
// pubspec.yaml
dependencies:
  app_tracking_transparency: ^2.0.0

// lib/services/tracking_service.dart
import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';

class TrackingService {
  /// ATT 상태 확인
  Future<TrackingStatus> getStatus() async {
    return await AppTrackingTransparency.trackingAuthorizationStatus;
  }

  /// ATT 권한 요청 (iOS 14.5+)
  Future<bool> requestTracking() async {
    // iOS가 아닌 경우 항상 true
    if (!Platform.isIOS) return true;

    final status = await AppTrackingTransparency.trackingAuthorizationStatus;

    switch (status) {
      case TrackingStatus.authorized:
        return true;
      case TrackingStatus.denied:
      case TrackingStatus.restricted:
        return false;
      case TrackingStatus.notDetermined:
        // 아직 요청하지 않은 경우에만 요청
        final result = await AppTrackingTransparency.requestTrackingAuthorization();
        return result == TrackingStatus.authorized;
      default:
        return false;
    }
  }

  /// IDFA 가져오기 (권한 있는 경우에만)
  Future<String?> getIDFA() async {
    if (await requestTracking()) {
      return await AppTrackingTransparency.getAdvertisingIdentifier();
    }
    return null;
  }
}

// 앱 시작 시 적절한 시점에 요청
class SplashPage extends StatefulWidget {
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 스플래시 표시 후 ATT 요청
    await Future.delayed(const Duration(seconds: 1));

    // ATT 요청 (결과와 관계없이 앱 진행)
    await TrackingService().requestTracking();

    // 홈으로 이동
    if (mounted) context.go('/home');
  }
}
```

### 11.4 ATT 요청 시점 권장사항

| 시점 | 권장 여부 | 이유 |
|-----|---------|------|
| 앱 첫 실행 즉시 | ❌ | 문맥 없이 요청하면 거부율 높음 |
| 온보딩 완료 후 | ✅ | 앱 가치를 경험한 후 요청 |
| 첫 광고 표시 전 | ✅ | 광고 관련 문맥에서 자연스러움 |
| 프리미엄 기능 사용 시 | ❌ | 기능과 무관해 보임 |

### 11.5 ATT 상태별 Analytics 설정

```dart
// Firebase Analytics에 ATT 상태 반영
Future<void> configureAnalyticsConsent() async {
  final status = await TrackingService().getStatus();

  final granted = status == TrackingStatus.authorized;

  await FirebaseAnalytics.instance.setConsent(
    adStorageConsentGranted: granted,
    adUserDataConsentGranted: granted,
    adPersonalizationSignalsConsentGranted: granted,
    analyticsStorageConsentGranted: true, // 분석은 항상 허용 가능
  );
}
```

## 테스트

### Mock PermissionService

```dart
// test/mocks/mock_permission_service.dart
import 'package:mocktail/mocktail.dart';
import 'package:permission_handler/permission_handler.dart';

class MockPermissionService extends Mock implements PermissionService {}

// 테스트
void main() {
  late MockPermissionService mockPermissionService;
  late PermissionBloc bloc;

  setUp(() {
    mockPermissionService = MockPermissionService();
    bloc = PermissionBloc(
      requestPermissionUseCase: RequestPermissionUseCase(mockPermissionService),
      permissionService: mockPermissionService,
    );
  });

  blocTest<PermissionBloc, PermissionState>(
    'should update status when permission granted',
    build: () {
      when(() => mockPermissionService.request(Permission.camera))
          .thenAnswer((_) async => PermissionStatus.granted);
      return bloc;
    },
    act: (bloc) => bloc.add(const PermissionEvent.requested(Permission.camera)),
    expect: () => [
      PermissionState.initial().copyWith(isLoading: true),
      PermissionState.initial().copyWith(
        isLoading: false,
        statuses: {Permission.camera: PermissionStatus.granted},
      ),
    ],
  );
}
```

## 실습 과제

### 과제 1: 권한 요청 화면 구현
카메라, 사진, 위치, 알림 4개 권한에 대해 각각 상태를 표시하고, 개별/전체 권한을 요청할 수 있는 온보딩 화면을 구현하세요. 각 권한 항목은 허용 여부에 따라 시각적으로 구분되어야 합니다.

### 과제 2: Pre-permission Rationale 적용
카메라 권한 요청 전에 사용 목적을 설명하는 다이얼로그를 표시하고, 사용자가 "계속"을 선택했을 때만 시스템 권한 팝업을 띄우는 흐름을 구현하세요.

### 과제 3: Android 13+ 저장소 권한 분기 처리
`device_info_plus`를 사용하여 Android SDK 버전을 확인하고, Android 13 이상에서는 `Permission.photos`/`Permission.videos`를, 이하에서는 `Permission.storage`를 요청하는 분기 로직을 구현하세요.

## Self-Check 퀴즈

- [ ] `PermissionStatus.denied`와 `PermissionStatus.permanentlyDenied`의 차이점과 각 상태에서의 대응 방법을 설명할 수 있는가?
- [ ] iOS에서 `PermissionStatus.limited` 상태가 발생하는 시점과 사용자에게 안내하는 방법을 이해하고 있는가?
- [ ] iOS Podfile에서 사용하지 않는 권한을 비활성화(PERMISSION_XXX=0)하는 이유를 설명할 수 있는가?
- [ ] `openAppSettings()`를 호출해야 하는 시점과 그 전에 사용자에게 안내해야 하는 내용을 이해하고 있는가?
- [ ] iOS App Tracking Transparency(ATT)의 요청 시점 권장사항과 거부 시 대응 방법을 설명할 수 있는가?

## 체크리스트

- [ ] permission_handler 패키지 설치
- [ ] iOS Info.plist에 권한 설명 추가
- [ ] iOS Podfile에서 사용하지 않는 권한 비활성화
- [ ] Android AndroidManifest.xml에 권한 추가
- [ ] PermissionService 인터페이스 및 구현체 작성
- [ ] 권한 요청 UseCase 작성
- [ ] PermissionBloc 구현
- [ ] 권한 요청 UI (다이얼로그, 페이지) 구현
- [ ] 영구 거부 시 설정 이동 처리
- [ ] iOS Limited Photo Access 처리 (필요시)
- [ ] 위치 서비스 활성화 확인 (위치 권한 사용시)
