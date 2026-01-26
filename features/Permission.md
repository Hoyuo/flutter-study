# Flutter 권한 처리 가이드 (permission_handler)

## 개요

permission_handler는 Flutter에서 iOS와 Android의 런타임 권한을 통합적으로 처리할 수 있는 패키지입니다. 카메라, 위치, 알림 등 다양한 권한을 일관된 API로 관리할 수 있습니다.

## 설치 및 설정

### 의존성 추가

```yaml
# pubspec.yaml
dependencies:
  permission_handler: ^11.3.0
```

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

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

  <!-- 카메라 -->
  <uses-permission android:name="android.permission.CAMERA"/>

  <!-- 저장소 (Android 12 이하) -->
  <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
  <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>

  <!-- 사진/비디오 (Android 13+) -->
  <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
  <uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>

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
  Permission.storage,
].request();

final cameraGranted = statuses[Permission.camera]?.isGranted ?? false;
final micGranted = statuses[Permission.microphone]?.isGranted ?? false;
final storageGranted = statuses[Permission.storage]?.isGranted ?? false;

if (cameraGranted && micGranted && storageGranted) {
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
