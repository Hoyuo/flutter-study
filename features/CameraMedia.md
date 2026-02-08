# Flutter 카메라 & 미디어 가이드

> Flutter에서 카메라, 갤러리, 비디오 재생, QR 스캔 등 미디어 관련 기능을 Clean Architecture와 Bloc 패턴으로 구현하는 종합 가이드입니다. camera, image_picker, video_player, mobile_scanner 패키지를 활용한 실전 예제를 다룹니다.

> **난이도**: 중급 | **카테고리**: features
> **선행 학습**: [Permission](./Permission.md) | **예상 학습 시간**: 1.5h

## 학습 목표

이 문서를 학습하면 다음을 할 수 있습니다:

1. camera 패키지를 사용하여 커스텀 카메라 UI(줌, 포커스, 플래시 제어)를 구현할 수 있다
2. image_picker로 갤러리/카메라에서 이미지/비디오를 선택하고 Bloc으로 상태 관리할 수 있다
3. video_player를 사용한 비디오 재생 위젯(재생/일시정지, 프로그레스 바)을 구현할 수 있다
4. mobile_scanner로 QR/바코드 스캔 기능을 구현할 수 있다
5. 이미지 크롭, 압축, 필터 적용 등 미디어 후처리 파이프라인을 구축할 수 있다

## 목차
1. [개요](#1-개요)
2. [프로젝트 설정](#2-프로젝트-설정)
3. [카메라 기본](#3-카메라-기본)
4. [사진 촬영](#4-사진-촬영)
5. [비디오 녹화](#5-비디오-녹화)
6. [이미지 피커](#6-이미지-피커)
7. [비디오 재생](#7-비디오-재생)
8. [QR/바코드 스캔](#8-qr바코드-스캔)
9. [이미지 처리](#9-이미지-처리)
10. [미디어 압축](#10-미디어-압축)
11. [Bloc 연동](#11-bloc-연동)
12. [Clean Architecture 연동](#12-clean-architecture-연동)
13. [테스트](#13-테스트)
14. [Best Practices](#14-best-practices)

---

## 1. 개요

### 1.1 주요 미디어 패키지 비교

| 패키지 | 용도 | 장점 | 단점 |
|--------|------|------|------|
| **camera** | 카메라 제어 | 세밀한 제어 가능, 커스터마이징 | 복잡한 설정 |
| **image_picker** | 갤러리/카메라 선택 | 간단한 API, 빠른 구현 | 제한적인 커스터마이징 |
| **video_player** | 비디오 재생 | 다양한 포맷 지원 | UI 직접 구현 필요 |
| **mobile_scanner** | QR/바코드 스캔 | 빠른 스캔, MLKit 기반 | 카메라 제어 제한적 |
| **flutter_image_compress** | 이미지 압축 | 네이티브 압축, 빠름 | Web 미지원 |
| **image** | 이미지 처리 | 순수 Dart, 다양한 필터 | 느린 처리 속도 |

### 1.2 사용 시나리오

```dart
// Scenario 1: 간단한 사진 선택
// → image_picker 사용

// Scenario 2: 커스텀 카메라 UI
// → camera 패키지 사용

// Scenario 3: QR 코드 스캔
// → mobile_scanner 사용

// Scenario 4: 비디오 재생 + 컨트롤
// → video_player + custom UI
```

---

## 2. 프로젝트 설정

### 2.1 프로젝트 구조

```
lib/
├── core/
│   ├── di/
│   │   └── injection.dart
│   ├── error/
│   │   └── failures.dart
│   └── utils/
│       └── media_utils.dart
├── features/
│   └── media/
│       ├── data/
│       │   ├── datasources/
│       │   │   ├── camera_datasource.dart
│       │   │   └── media_datasource.dart
│       │   ├── models/
│       │   │   ├── media_file_model.dart
│       │   │   └── scan_result_model.dart
│       │   └── repositories/
│       │       └── media_repository_impl.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── media_file.dart
│       │   │   └── scan_result.dart
│       │   ├── repositories/
│       │   │   └── media_repository.dart
│       │   └── usecases/
│       │       ├── capture_photo.dart
│       │       ├── pick_image.dart
│       │       └── scan_qr_code.dart
│       └── presentation/
│           ├── bloc/
│           │   ├── camera_bloc.dart
│           │   ├── media_bloc.dart
│           │   └── video_bloc.dart
│           ├── pages/
│           │   ├── camera_page.dart
│           │   ├── gallery_page.dart
│           │   └── qr_scanner_page.dart
│           └── widgets/
│               ├── camera_preview_widget.dart
│               └── video_player_widget.dart
└── main.dart
```

### 2.2 pubspec.yaml

```yaml
# pubspec.yaml
name: camera_media_example
description: Camera and Media features with Clean Architecture
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.10.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_bloc: ^9.1.1

  # DI
  injectable: ^2.7.1
  get_it: ^9.2.0

  # Functional Programming
  fpdart: ^1.2.0

  # Code Generation
  freezed_annotation: ^3.1.0
  json_annotation: ^4.10.0

  # Camera & Media
  camera: ^0.11.3
  image_picker: ^1.2.1
  video_player: ^2.10.1
  mobile_scanner: ^7.1.4

  # Image Processing
  flutter_image_compress: ^2.4.0
  image: ^4.7.2
  image_cropper: ^11.0.0

  # Video Processing
  video_compress: ^3.1.4

  # Permissions
  permission_handler: ^12.0.1

  # Path
  path_provider: ^2.1.5
  path: ^1.9.1

dev_dependencies:
  flutter_test:
    sdk: flutter

  # Code Generation
  build_runner: ^2.11.0
  freezed: ^3.2.5
  json_serializable: ^6.12.0
  injectable_generator: ^2.12.0

  # Testing
  bloc_test: ^10.0.0
  mocktail: ^1.0.4

  lints: ^6.1.0
```

### 2.3 Android 권한 설정

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Camera Permissions -->
    <uses-permission android:name="android.permission.CAMERA" />

    <!-- Storage Permissions -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
                     android:maxSdkVersion="32" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
                     android:maxSdkVersion="32" />

    <!-- Android 13+ Photo Picker -->
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
    <uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />

    <!-- Microphone for video recording -->
    <uses-permission android:name="android.permission.RECORD_AUDIO" />

    <!-- Camera Features -->
    <uses-feature android:name="android.hardware.camera" android:required="false" />
    <uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />

    <application
        android:requestLegacyExternalStorage="true"
        ...>
        ...
    </application>
</manifest>
```

### 2.4 iOS 권한 설정

```xml
<!-- ios/Runner/Info.plist -->
<dict>
    <!-- Camera -->
    <key>NSCameraUsageDescription</key>
    <string>사진 및 비디오 촬영을 위해 카메라 접근이 필요합니다</string>

    <!-- Photo Library -->
    <key>NSPhotoLibraryUsageDescription</key>
    <string>사진을 선택하기 위해 갤러리 접근이 필요합니다</string>
    <key>NSPhotoLibraryAddUsageDescription</key>
    <string>사진을 저장하기 위해 갤러리 접근이 필요합니다</string>

    <!-- Microphone -->
    <key>NSMicrophoneUsageDescription</key>
    <string>비디오 녹화를 위해 마이크 접근이 필요합니다</string>
</dict>
```

---

## 3. 카메라 기본

### 3.1 Entity 정의

```dart
// lib/features/media/domain/entities/media_file.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'media_file.freezed.dart';

@freezed
class MediaFile with _$MediaFile {
  const factory MediaFile({
    required String path,
    required MediaType type,
    required int size,
    required DateTime createdAt,
    String? thumbnailPath,
    Duration? duration, // For video
    int? width,
    int? height,
  }) = _MediaFile;
}

enum MediaType {
  image,
  video,
}
```

### 3.2 Camera DataSource

```dart
// lib/features/media/data/datasources/camera_datasource.dart
import 'package:camera/camera.dart';
import 'package:injectable/injectable.dart';

abstract class CameraDataSource {
  Future<List<CameraDescription>> getAvailableCameras();
  Future<CameraController> initializeCamera({
    required CameraDescription camera,
    ResolutionPreset resolution = ResolutionPreset.high,
    bool enableAudio = true,
  });
  Future<void> disposeCamera(CameraController controller);
}

@LazySingleton(as: CameraDataSource)
class CameraDataSourceImpl implements CameraDataSource {
  @override
  Future<List<CameraDescription>> getAvailableCameras() async {
    try {
      return await availableCameras();
    } catch (e) {
      throw CameraException('CAMERA_ERROR', 'Failed to get cameras: $e');
    }
  }

  @override
  Future<CameraController> initializeCamera({
    required CameraDescription camera,
    ResolutionPreset resolution = ResolutionPreset.high,
    bool enableAudio = true,
  }) async {
    final controller = CameraController(
      camera,
      resolution,
      enableAudio: enableAudio,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await controller.initialize();
      return controller;
    } catch (e) {
      await controller.dispose();
      throw CameraException('INIT_ERROR', 'Failed to initialize camera: $e');
    }
  }

  @override
  Future<void> disposeCamera(CameraController controller) async {
    await controller.dispose();
  }
}
```

### 3.3 Camera Preview Widget

```dart
// lib/features/media/presentation/widgets/camera_preview_widget.dart
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraPreviewWidget extends StatelessWidget {
  final CameraController controller;
  final Widget? overlay;

  const CameraPreviewWidget({
    super.key,
    required this.controller,
    this.overlay,
  });

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(controller),
          if (overlay != null) overlay!,
        ],
      ),
    );
  }
}
```

---

## 4. 사진 촬영

### 4.1 Capture Photo UseCase

```dart
// lib/features/media/domain/usecases/capture_photo.dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import '../entities/media_file.dart';
import '../repositories/media_repository.dart';
import '../../../../core/error/failures.dart';

@lazySingleton
class CapturePhoto {
  final MediaRepository repository;

  CapturePhoto(this.repository);

  Future<Either<Failure, MediaFile>> call({
    bool enableFlash = false,
  }) async {
    return repository.capturePhoto(enableFlash: enableFlash);
  }
}
```

### 4.2 Photo Capture Implementation

```dart
// lib/features/media/data/datasources/media_datasource.dart
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

abstract class MediaDataSource {
  Future<String> capturePhoto(CameraController controller);
  Future<String> startVideoRecording(CameraController controller);
  Future<String> stopVideoRecording(CameraController controller);
}

@LazySingleton(as: MediaDataSource)
class MediaDataSourceImpl implements MediaDataSource {
  @override
  Future<String> capturePhoto(CameraController controller) async {
    if (!controller.value.isInitialized) {
      throw CameraException('NOT_INITIALIZED', 'Camera not initialized');
    }

    if (controller.value.isTakingPicture) {
      throw CameraException('ALREADY_CAPTURING', 'Already taking a picture');
    }

    try {
      // Generate unique file path
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = path.join(
        directory.path,
        'photo_$timestamp.jpg',
      );

      // Capture photo
      final XFile photo = await controller.takePicture();

      // Move to permanent location
      final File imageFile = File(photo.path);
      await imageFile.copy(filePath);
      await imageFile.delete();

      return filePath;
    } catch (e) {
      throw CameraException('CAPTURE_ERROR', 'Failed to capture photo: $e');
    }
  }

  @override
  Future<String> startVideoRecording(CameraController controller) async {
    if (!controller.value.isInitialized) {
      throw CameraException('NOT_INITIALIZED', 'Camera not initialized');
    }

    if (controller.value.isRecordingVideo) {
      throw CameraException('ALREADY_RECORDING', 'Already recording video');
    }

    try {
      await controller.startVideoRecording();
      return 'Recording started';
    } catch (e) {
      throw CameraException('RECORDING_ERROR', 'Failed to start recording: $e');
    }
  }

  @override
  Future<String> stopVideoRecording(CameraController controller) async {
    if (!controller.value.isRecordingVideo) {
      throw CameraException('NOT_RECORDING', 'Not recording video');
    }

    try {
      final XFile video = await controller.stopVideoRecording();

      // Move to permanent location
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = path.join(
        directory.path,
        'video_$timestamp.mp4',
      );

      final File videoFile = File(video.path);
      await videoFile.copy(filePath);
      await videoFile.delete();

      return filePath;
    } catch (e) {
      throw CameraException('STOP_ERROR', 'Failed to stop recording: $e');
    }
  }
}
```

### 4.3 Camera Controls

```dart
// lib/features/media/presentation/widgets/camera_controls.dart
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraControls extends StatelessWidget {
  final CameraController controller;
  final VoidCallback onCapture;
  final VoidCallback onSwitchCamera;
  final bool isFlashOn;
  final VoidCallback onFlashToggle;

  const CameraControls({
    super.key,
    required this.controller,
    required this.onCapture,
    required this.onSwitchCamera,
    required this.isFlashOn,
    required this.onFlashToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Flash toggle
          IconButton(
            icon: Icon(
              isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
            onPressed: onFlashToggle,
            iconSize: 32,
          ),

          // Capture button
          GestureDetector(
            onTap: onCapture,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 4,
                ),
              ),
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          // Switch camera
          IconButton(
            icon: const Icon(
              Icons.flip_camera_ios,
              color: Colors.white,
            ),
            onPressed: onSwitchCamera,
            iconSize: 32,
          ),
        ],
      ),
    );
  }
}
```

### 4.4 Zoom & Focus Control

```dart
// lib/features/media/presentation/widgets/zoom_focus_widget.dart
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class ZoomFocusWidget extends StatefulWidget {
  final CameraController controller;

  const ZoomFocusWidget({
    super.key,
    required this.controller,
  });

  @override
  State<ZoomFocusWidget> createState() => _ZoomFocusWidgetState();
}

class _ZoomFocusWidgetState extends State<ZoomFocusWidget> {
  double _currentZoom = 1.0;
  double _maxZoom = 1.0;
  double _minZoom = 1.0;

  @override
  void initState() {
    super.initState();
    _initZoom();
  }

  Future<void> _initZoom() async {
    _maxZoom = await widget.controller.getMaxZoomLevel();
    _minZoom = await widget.controller.getMinZoomLevel();
    setState(() {});
  }

  Future<void> _setZoom(double zoom) async {
    final clampedZoom = zoom.clamp(_minZoom, _maxZoom);
    await widget.controller.setZoomLevel(clampedZoom);
    setState(() => _currentZoom = clampedZoom);
  }

  Future<void> _setFocusPoint(Offset point, BoxConstraints constraints) async {
    if (!widget.controller.value.isInitialized) return;

    final dx = point.dx / constraints.maxWidth;
    final dy = point.dy / constraints.maxHeight;

    try {
      await widget.controller.setFocusPoint(Offset(dx, dy));
      await widget.controller.setExposurePoint(Offset(dx, dy));

      // Show focus indicator
      _showFocusIndicator(point);
    } catch (e) {
      debugPrint('Focus error: $e');
    }
  }

  void _showFocusIndicator(Offset point) {
    // Implement focus indicator animation
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapUp: (details) {
            _setFocusPoint(details.localPosition, constraints);
          },
          onScaleUpdate: (details) {
            _setZoom(_currentZoom * details.scale);
          },
          child: Stack(
            children: [
              // Camera preview
              SizedBox.expand(
                child: CameraPreview(widget.controller),
              ),

              // Zoom slider
              Positioned(
                right: 16,
                top: 100,
                bottom: 100,
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Slider(
                    value: _currentZoom,
                    min: _minZoom,
                    max: _maxZoom,
                    onChanged: _setZoom,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

---

## 5. 비디오 녹화

### 5.1 Video Recording Bloc State

```dart
// lib/features/media/presentation/bloc/video_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:camera/camera.dart';

part 'video_bloc.freezed.dart';

@freezed
class VideoEvent with _$VideoEvent {
  const factory VideoEvent.startRecording() = _StartRecording;
  const factory VideoEvent.stopRecording() = _StopRecording;
  const factory VideoEvent.pauseRecording() = _PauseRecording;
  const factory VideoEvent.resumeRecording() = _ResumeRecording;
  const factory VideoEvent.updateDuration(Duration duration) = _UpdateDuration;
}

@freezed
class VideoState with _$VideoState {
  const factory VideoState({
    @Default(false) bool isRecording,
    @Default(false) bool isPaused,
    @Default(Duration.zero) Duration duration,
    String? videoPath,
    String? error,
  }) = _VideoState;
}

class VideoBloc extends Bloc<VideoEvent, VideoState> {
  final CameraController cameraController;

  VideoBloc(this.cameraController) : super(const VideoState()) {
    on<_StartRecording>(_onStartRecording);
    on<_StopRecording>(_onStopRecording);
    on<_PauseRecording>(_onPauseRecording);
    on<_ResumeRecording>(_onResumeRecording);
    on<_UpdateDuration>(_onUpdateDuration);
  }

  Future<void> _onStartRecording(
    _StartRecording event,
    Emitter<VideoState> emit,
  ) async {
    try {
      await cameraController.startVideoRecording();
      emit(state.copyWith(isRecording: true, isPaused: false, error: null));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onStopRecording(
    _StopRecording event,
    Emitter<VideoState> emit,
  ) async {
    try {
      final video = await cameraController.stopVideoRecording();
      emit(state.copyWith(
        isRecording: false,
        isPaused: false,
        videoPath: video.path,
        duration: Duration.zero,
      ));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onPauseRecording(
    _PauseRecording event,
    Emitter<VideoState> emit,
  ) async {
    try {
      await cameraController.pauseVideoRecording();
      emit(state.copyWith(isPaused: true));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onResumeRecording(
    _ResumeRecording event,
    Emitter<VideoState> emit,
  ) async {
    try {
      await cameraController.resumeVideoRecording();
      emit(state.copyWith(isPaused: false));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  void _onUpdateDuration(
    _UpdateDuration event,
    Emitter<VideoState> emit,
  ) {
    emit(state.copyWith(duration: event.duration));
  }
}
```

### 5.2 Video Recording Controls

```dart
// lib/features/media/presentation/widgets/video_controls.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/video_bloc.dart';

class VideoControls extends StatelessWidget {
  final Duration? maxDuration;

  const VideoControls({
    super.key,
    this.maxDuration,
  });

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VideoBloc, VideoState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Duration display
              if (state.isRecording || state.videoPath != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (state.isRecording && !state.isPaused)
                        Container(
                          width: 12,
                          height: 12,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      Text(
                        _formatDuration(state.duration),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (maxDuration != null)
                        Text(
                          ' / ${_formatDuration(maxDuration!)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Control buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Pause/Resume button
                  if (state.isRecording)
                    IconButton(
                      icon: Icon(
                        state.isPaused ? Icons.play_arrow : Icons.pause,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        if (state.isPaused) {
                          context.read<VideoBloc>().add(
                                const VideoEvent.resumeRecording(),
                              );
                        } else {
                          context.read<VideoBloc>().add(
                                const VideoEvent.pauseRecording(),
                              );
                        }
                      },
                      iconSize: 32,
                    ),

                  // Record/Stop button
                  GestureDetector(
                    onTap: () {
                      if (state.isRecording) {
                        context.read<VideoBloc>().add(
                              const VideoEvent.stopRecording(),
                            );
                      } else {
                        context.read<VideoBloc>().add(
                              const VideoEvent.startRecording(),
                            );
                      }
                    },
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: state.isRecording ? Colors.red : Colors.white,
                          shape: state.isRecording
                              ? BoxShape.rectangle
                              : BoxShape.circle,
                          borderRadius: state.isRecording
                              ? BorderRadius.circular(8)
                              : null,
                        ),
                      ),
                    ),
                  ),

                  // Placeholder for symmetry
                  if (state.isRecording)
                    const SizedBox(width: 48)
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
```

---

## 6. 이미지 피커

### 6.1 Pick Image UseCase

```dart
// lib/features/media/domain/usecases/pick_image.dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import '../entities/media_file.dart';
import '../repositories/media_repository.dart';
import '../../../../core/error/failures.dart';

enum ImageSource {
  camera,
  gallery,
}

@lazySingleton
class PickImage {
  final MediaRepository repository;

  PickImage(this.repository);

  Future<Either<Failure, MediaFile>> call({
    required ImageSource source,
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
  }) async {
    return repository.pickImage(
      source: source,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
  }

  Future<Either<Failure, List<MediaFile>>> pickMultiple({
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
    int? limit,
  }) async {
    return repository.pickMultipleImages(
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
      limit: limit,
    );
  }
}
```

### 6.2 Image Picker Implementation

```dart
// lib/features/media/data/repositories/media_repository_impl.dart
import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:image_picker/image_picker.dart' as picker;
import 'package:injectable/injectable.dart';
import '../../domain/entities/media_file.dart';
import '../../domain/repositories/media_repository.dart';
import '../../domain/usecases/pick_image.dart';
import '../../../../core/error/failures.dart';

@LazySingleton(as: MediaRepository)
class MediaRepositoryImpl implements MediaRepository {
  final picker.ImagePicker _imagePicker;

  MediaRepositoryImpl() : _imagePicker = picker.ImagePicker();

  @override
  Future<Either<Failure, MediaFile>> pickImage({
    required ImageSource source,
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
  }) async {
    try {
      final pickerSource = source == ImageSource.camera
          ? picker.ImageSource.camera
          : picker.ImageSource.gallery;

      final pickedFile = await _imagePicker.pickImage(
        source: pickerSource,
        maxWidth: maxWidth?.toDouble(),
        maxHeight: maxHeight?.toDouble(),
        imageQuality: imageQuality,
      );

      if (pickedFile == null) {
        return Left(CancelledFailure());
      }

      final file = File(pickedFile.path);
      final fileSize = await file.length();

      return Right(MediaFile(
        path: pickedFile.path,
        type: MediaType.image,
        size: fileSize,
        createdAt: DateTime.now(),
      ));
    } catch (e) {
      return Left(MediaFailure('Failed to pick image: $e'));
    }
  }

  @override
  Future<Either<Failure, List<MediaFile>>> pickMultipleImages({
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
    int? limit,
  }) async {
    try {
      final pickedFiles = await _imagePicker.pickMultiImage(
        maxWidth: maxWidth?.toDouble(),
        maxHeight: maxHeight?.toDouble(),
        imageQuality: imageQuality,
        limit: limit,
      );

      if (pickedFiles.isEmpty) {
        return Left(CancelledFailure());
      }

      final mediaFiles = <MediaFile>[];
      for (final pickedFile in pickedFiles) {
        final file = File(pickedFile.path);
        final fileSize = await file.length();

        mediaFiles.add(MediaFile(
          path: pickedFile.path,
          type: MediaType.image,
          size: fileSize,
          createdAt: DateTime.now(),
        ));
      }

      return Right(mediaFiles);
    } catch (e) {
      return Left(MediaFailure('Failed to pick images: $e'));
    }
  }

  @override
  Future<Either<Failure, MediaFile>> pickVideo({
    required ImageSource source,
    Duration? maxDuration,
  }) async {
    try {
      final pickerSource = source == ImageSource.camera
          ? picker.ImageSource.camera
          : picker.ImageSource.gallery;

      final pickedFile = await _imagePicker.pickVideo(
        source: pickerSource,
        maxDuration: maxDuration,
      );

      if (pickedFile == null) {
        return Left(CancelledFailure());
      }

      final file = File(pickedFile.path);
      final fileSize = await file.length();

      return Right(MediaFile(
        path: pickedFile.path,
        type: MediaType.video,
        size: fileSize,
        createdAt: DateTime.now(),
      ));
    } catch (e) {
      return Left(MediaFailure('Failed to pick video: $e'));
    }
  }
}
```

### 6.3 Image Picker Widget

```dart
// lib/features/media/presentation/widgets/image_picker_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/media_bloc.dart';
import '../../domain/usecases/pick_image.dart';

class ImagePickerWidget extends StatelessWidget {
  final bool allowMultiple;
  final Function(List<String> paths) onImagesPicked;

  const ImagePickerWidget({
    super.key,
    this.allowMultiple = false,
    required this.onImagesPicked,
  });

  Future<void> _showPickerOptions(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('카메라로 촬영'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(context, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(
                allowMultiple ? '갤러리에서 여러 장 선택' : '갤러리에서 선택',
              ),
              onTap: () {
                Navigator.pop(context);
                if (allowMultiple) {
                  _pickMultipleImages(context);
                } else {
                  _pickImage(context, ImageSource.gallery);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _pickImage(BuildContext context, ImageSource source) {
    context.read<MediaBloc>().add(
          MediaEvent.pickImage(
            source: source,
            imageQuality: 85,
          ),
        );
  }

  void _pickMultipleImages(BuildContext context) {
    context.read<MediaBloc>().add(
          const MediaEvent.pickMultipleImages(
            imageQuality: 85,
            limit: 10,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MediaBloc, MediaState>(
      listener: (context, state) {
        state.maybeWhen(
          loaded: (files) {
            onImagesPicked(files.map((f) => f.path).toList());
          },
          error: (message) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          },
          orElse: () {},
        );
      },
      child: ElevatedButton.icon(
        onPressed: () => _showPickerOptions(context),
        icon: const Icon(Icons.add_photo_alternate),
        label: Text(allowMultiple ? '사진 선택' : '사진 추가'),
      ),
    );
  }
}
```

---

## 7. 비디오 재생

### 7.1 Video Player Widget

```dart
// lib/features/media/presentation/widgets/video_player_widget.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

class VideoPlayerWidget extends StatefulWidget {
  final String videoPath;
  final bool autoPlay;
  final bool looping;

  const VideoPlayerWidget({
    super.key,
    required this.videoPath,
    this.autoPlay = false,
    this.looping = false,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.file(File(widget.videoPath));

    await _controller.initialize();
    _controller.setLooping(widget.looping);

    if (widget.autoPlay) {
      await _controller.play();
    }

    setState(() => _isInitialized = true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return GestureDetector(
      onTap: () => setState(() => _showControls = !_showControls),
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_controller),

            // Play/Pause overlay
            if (_showControls)
              AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  color: Colors.black38,
                  child: Center(
                    child: IconButton(
                      icon: Icon(
                        _controller.value.isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        size: 64,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          if (_controller.value.isPlaying) {
                            _controller.pause();
                          } else {
                            _controller.play();
                          }
                        });
                      },
                    ),
                  ),
                ),
              ),

            // Bottom controls
            if (_showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _VideoControls(controller: _controller),
              ),
          ],
        ),
      ),
    );
  }
}

class _VideoControls extends StatefulWidget {
  final VideoPlayerController controller;

  const _VideoControls({required this.controller});

  @override
  State<_VideoControls> createState() => _VideoControlsState();
}

class _VideoControlsState extends State<_VideoControls> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      setState(() {});
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black54],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          VideoProgressIndicator(
            widget.controller,
            allowScrubbing: true,
            colors: const VideoProgressColors(
              playedColor: Colors.red,
              bufferedColor: Colors.grey,
              backgroundColor: Colors.white24,
            ),
          ),

          // Time and fullscreen
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_formatDuration(widget.controller.value.position)} / ${_formatDuration(widget.controller.value.duration)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.fullscreen,
                  color: Colors.white,
                ),
                onPressed: () {
                  // Implement fullscreen
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

---

## 8. QR/바코드 스캔

### 8.1 Scan Result Entity

```dart
// lib/features/media/domain/entities/scan_result.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:ui';

part 'scan_result.freezed.dart';

@freezed
class ScanResult with _$ScanResult {
  const factory ScanResult({
    required String rawValue,
    required BarcodeFormat format,
    required DateTime scannedAt,
    List<Offset>? corners,
  }) = _ScanResult;
}

enum BarcodeFormat {
  qrCode,
  ean8,
  ean13,
  code128,
  code39,
  unknown,
}
```

### 8.2 QR Scanner Widget

```dart
// lib/features/media/presentation/widgets/qr_scanner_widget.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerWidget extends StatefulWidget {
  final Function(String code) onCodeScanned;
  final bool showOverlay;

  const QRScannerWidget({
    super.key,
    required this.onCodeScanned,
    this.showOverlay = true,
  });

  @override
  State<QRScannerWidget> createState() => _QRScannerWidgetState();
}

class _QRScannerWidgetState extends State<QRScannerWidget> {
  late MobileScannerController _controller;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture barcodeCapture) {
    if (_isProcessing) return;

    final barcode = barcodeCapture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    setState(() => _isProcessing = true);
    widget.onCodeScanned(barcode!.rawValue!);

    // Reset after delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: _handleBarcode,
        ),

        if (widget.showOverlay)
          _ScannerOverlay(
            borderColor: _isProcessing ? Colors.green : Colors.white,
          ),

        // Torch toggle
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: Center(
            child: IconButton(
              icon: ValueListenableBuilder(
                valueListenable: _controller.torchState,
                builder: (context, state, child) {
                  return Icon(
                    state == TorchState.on ? Icons.flash_on : Icons.flash_off,
                    color: Colors.white,
                    size: 32,
                  );
                },
              ),
              onPressed: () => _controller.toggleTorch(),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  final Color borderColor;

  const _ScannerOverlay({
    this.borderColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
      ),
      child: Stack(
        children: [
          // Center cutout
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: borderColor,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // Instructions
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Text(
              'QR 코드를 사각형 안에 맞춰주세요',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.8),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 9. 이미지 처리

### 9.1 Image Crop

```dart
// lib/core/utils/image_utils.dart
import 'dart:io';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter/material.dart';

class ImageUtils {
  static Future<File?> cropImage(
    String imagePath, {
    CropAspectRatio? aspectRatio,
    List<CropAspectRatioPreset>? aspectRatioPresets,
  }) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imagePath,
      aspectRatio: aspectRatio,
      aspectRatioPresets: aspectRatioPresets ?? [
        CropAspectRatioPreset.square,
        CropAspectRatioPreset.ratio3x2,
        CropAspectRatioPreset.ratio4x3,
        CropAspectRatioPreset.ratio16x9,
      ],
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '이미지 편집',
          toolbarColor: Colors.blue,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: '이미지 편집',
          minimumAspectRatio: 1.0,
        ),
      ],
    );

    return croppedFile != null ? File(croppedFile.path) : null;
  }
}
```

### 9.2 Image Compression

```dart
// lib/core/utils/compression_utils.dart
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class CompressionUtils {
  static Future<File?> compressImage(
    File file, {
    int quality = 85,
    int? maxWidth,
    int? maxHeight,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final targetPath = path.join(
      tempDir.path,
      'compressed_$timestamp.jpg',
    );

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: quality,
      minWidth: maxWidth ?? 1920,
      minHeight: maxHeight ?? 1080,
      format: CompressFormat.jpeg,
    );

    return result != null ? File(result.path) : null;
  }

  static Future<int> getImageSize(File file) async {
    return await file.length();
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
```

### 9.3 Image Filters & Processing

```dart
// lib/core/utils/image_processing.dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';

class ImageProcessing {
  static Future<File> applyGrayscale(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes)!;
    final grayscale = img.grayscale(image);

    final newFile = File('${imageFile.path}_grayscale.jpg');
    await newFile.writeAsBytes(img.encodeJpg(grayscale));
    return newFile;
  }

  static Future<File> applySepia(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes)!;
    final sepia = img.sepia(image);

    final newFile = File('${imageFile.path}_sepia.jpg');
    await newFile.writeAsBytes(img.encodeJpg(sepia));
    return newFile;
  }

  static Future<File> adjustBrightness(
    File imageFile,
    int brightness, // -255 to 255
  ) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes)!;
    final adjusted = img.brightness(image, brightness: brightness);

    final newFile = File('${imageFile.path}_bright.jpg');
    await newFile.writeAsBytes(img.encodeJpg(adjusted));
    return newFile;
  }

  static Future<File> resizeImage(
    File imageFile, {
    required int width,
    required int height,
  }) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes)!;
    final resized = img.copyResize(
      image,
      width: width,
      height: height,
      interpolation: img.Interpolation.linear,
    );

    final newFile = File('${imageFile.path}_resized.jpg');
    await newFile.writeAsBytes(img.encodeJpg(resized));
    return newFile;
  }

  static Future<File> addWatermark(
    File imageFile,
    String watermarkText, {
    int fontSize = 24,
    ui.Color color = const ui.Color.fromARGB(255, 255, 255, 255),
  }) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes)!;

    img.drawString(
      image,
      watermarkText,
      font: img.arial24,
      x: 10,
      y: image.height - 30,
      color: img.ColorRgb8(color.red, color.green, color.blue),
    );

    final newFile = File('${imageFile.path}_watermark.jpg');
    await newFile.writeAsBytes(img.encodeJpg(image));
    return newFile;
  }
}
```

---

## 10. 미디어 압축

### 10.1 Video Compression

```dart
// lib/core/utils/video_compression.dart
import 'dart:io';
import 'package:video_compress/video_compress.dart';

class VideoCompressionUtils {
  static Future<File?> compressVideo(
    File videoFile, {
    VideoQuality quality = VideoQuality.MediumQuality,
    bool deleteOrigin = false,
  }) async {
    try {
      final info = await VideoCompress.compressVideo(
        videoFile.path,
        quality: quality,
        deleteOrigin: deleteOrigin,
        includeAudio: true,
      );

      return info?.file;
    } catch (e) {
      return null;
    }
  }

  static Future<void> cancelCompression() async {
    await VideoCompress.cancelCompression();
  }

  static Stream<double> getCompressionProgress() {
    return VideoCompress.compressProgress$.map((progress) => progress);
  }

  static Future<MediaInfo?> getVideoInfo(String path) async {
    return await VideoCompress.getMediaInfo(path);
  }

  static Future<File?> getThumbnail(
    String videoPath, {
    int quality = 50,
    int position = -1, // -1 for middle
  }) async {
    final thumbnail = await VideoCompress.getFileThumbnail(
      videoPath,
      quality: quality,
      position: position,
    );
    return thumbnail;
  }

  static void deleteAllCache() {
    VideoCompress.deleteAllCache();
  }
}
```

### 10.2 Compression Widget with Progress

```dart
// lib/features/media/presentation/widgets/compression_widget.dart
import 'package:flutter/material.dart';
import 'dart:io';
import '../../../../core/utils/video_compression.dart';
import '../../../../core/utils/compression_utils.dart';

class CompressionWidget extends StatefulWidget {
  final File file;
  final bool isVideo;
  final Function(File compressedFile) onComplete;

  const CompressionWidget({
    super.key,
    required this.file,
    required this.isVideo,
    required this.onComplete,
  });

  @override
  State<CompressionWidget> createState() => _CompressionWidgetState();
}

class _CompressionWidgetState extends State<CompressionWidget> {
  double _progress = 0.0;
  bool _isCompressing = false;
  String? _originalSize;
  String? _compressedSize;

  @override
  void initState() {
    super.initState();
    _loadOriginalSize();
  }

  Future<void> _loadOriginalSize() async {
    final size = await widget.file.length();
    setState(() {
      _originalSize = CompressionUtils.formatFileSize(size);
    });
  }

  Future<void> _startCompression() async {
    setState(() => _isCompressing = true);

    if (widget.isVideo) {
      await _compressVideo();
    } else {
      await _compressImage();
    }
  }

  Future<void> _compressVideo() async {
    VideoCompressionUtils.getCompressionProgress().listen((progress) {
      setState(() => _progress = progress / 100);
    });

    final compressed = await VideoCompressionUtils.compressVideo(
      widget.file,
      quality: VideoQuality.MediumQuality,
    );

    if (compressed != null) {
      final size = await compressed.length();
      setState(() {
        _compressedSize = CompressionUtils.formatFileSize(size);
        _isCompressing = false;
      });
      widget.onComplete(compressed);
    }
  }

  Future<void> _compressImage() async {
    final compressed = await CompressionUtils.compressImage(
      widget.file,
      quality: 85,
    );

    if (compressed != null) {
      final size = await compressed.length();
      setState(() {
        _compressedSize = CompressionUtils.formatFileSize(size);
        _isCompressing = false;
        _progress = 1.0;
      });
      widget.onComplete(compressed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isVideo ? '비디오 압축' : '이미지 압축',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            if (_originalSize != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('원본 크기:'),
                  Text(
                    _originalSize!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),

            if (_compressedSize != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('압축 후:'),
                  Text(
                    _compressedSize!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            if (_isCompressing) ...[
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 8),
              Text('${(_progress * 100).toInt()}%'),
            ] else if (_compressedSize == null)
              ElevatedButton(
                onPressed: _startCompression,
                child: const Text('압축 시작'),
              ),
          ],
        ),
      ),
    );
  }
}
```

---

## 11. Bloc 연동

### 11.1 Media Bloc

```dart
// lib/features/media/presentation/bloc/media_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/media_file.dart';
import '../../domain/usecases/pick_image.dart';
import '../../domain/usecases/capture_photo.dart';

part 'media_bloc.freezed.dart';

@freezed
class MediaEvent with _$MediaEvent {
  const factory MediaEvent.pickImage({
    required ImageSource source,
    int? imageQuality,
  }) = _PickImage;

  const factory MediaEvent.pickMultipleImages({
    int? imageQuality,
    int? limit,
  }) = _PickMultipleImages;

  const factory MediaEvent.capturePhoto({
    @Default(false) bool enableFlash,
  }) = _CapturePhoto;

  const factory MediaEvent.clearMedia() = _ClearMedia;
}

@freezed
class MediaState with _$MediaState {
  const factory MediaState.initial() = _Initial;
  const factory MediaState.loading() = _Loading;
  const factory MediaState.loaded(List<MediaFile> files) = _Loaded;
  const factory MediaState.error(String message) = _Error;
}

@injectable
class MediaBloc extends Bloc<MediaEvent, MediaState> {
  final PickImage _pickImage;
  final CapturePhoto _capturePhoto;

  MediaBloc(
    this._pickImage,
    this._capturePhoto,
  ) : super(const MediaState.initial()) {
    on<_PickImage>(_onPickImage);
    on<_PickMultipleImages>(_onPickMultipleImages);
    on<_CapturePhoto>(_onCapturePhoto);
    on<_ClearMedia>(_onClearMedia);
  }

  Future<void> _onPickImage(
    _PickImage event,
    Emitter<MediaState> emit,
  ) async {
    emit(const MediaState.loading());

    final result = await _pickImage(
      source: event.source,
      imageQuality: event.imageQuality,
    );

    result.fold(
      (failure) => emit(MediaState.error(failure.message)),
      (file) => emit(MediaState.loaded([file])),
    );
  }

  Future<void> _onPickMultipleImages(
    _PickMultipleImages event,
    Emitter<MediaState> emit,
  ) async {
    emit(const MediaState.loading());

    final result = await _pickImage.pickMultiple(
      imageQuality: event.imageQuality,
      limit: event.limit,
    );

    result.fold(
      (failure) => emit(MediaState.error(failure.message)),
      (files) => emit(MediaState.loaded(files)),
    );
  }

  Future<void> _onCapturePhoto(
    _CapturePhoto event,
    Emitter<MediaState> emit,
  ) async {
    emit(const MediaState.loading());

    final result = await _capturePhoto(enableFlash: event.enableFlash);

    result.fold(
      (failure) => emit(MediaState.error(failure.message)),
      (file) => emit(MediaState.loaded([file])),
    );
  }

  void _onClearMedia(_ClearMedia event, Emitter<MediaState> emit) {
    emit(const MediaState.initial());
  }
}
```

---

## 12. Clean Architecture 연동

### 12.1 Failure 정의

```dart
// lib/core/error/failures.dart
abstract class Failure {
  final String message;

  const Failure(this.message);
}

class MediaFailure extends Failure {
  const MediaFailure(super.message);
}

class CancelledFailure extends Failure {
  const CancelledFailure() : super('Operation cancelled by user');
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}
```

### 12.2 Domain Repository

```dart
// lib/features/media/domain/repositories/media_repository.dart
import 'package:fpdart/fpdart.dart';
import 'dart:io';
import '../entities/media_file.dart';
import '../entities/scan_result.dart';
import '../usecases/pick_image.dart';
import '../../../../core/error/failures.dart';

abstract class MediaRepository {
  Future<Either<Failure, MediaFile>> pickImage({
    required ImageSource source,
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
  });

  Future<Either<Failure, List<MediaFile>>> pickMultipleImages({
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
    int? limit,
  });

  Future<Either<Failure, MediaFile>> pickVideo({
    required ImageSource source,
    Duration? maxDuration,
  });

  Future<Either<Failure, MediaFile>> capturePhoto({
    bool enableFlash = false,
  });

  Future<Either<Failure, MediaFile>> recordVideo({
    Duration? maxDuration,
  });

  Future<Either<Failure, ScanResult>> scanQRCode();

  Future<Either<Failure, File>> compressImage(
    File file, {
    int quality = 85,
  });

  Future<Either<Failure, File>> compressVideo(
    File file, {
    VideoQuality quality = VideoQuality.MediumQuality,
  });
}
```

### 12.3 Dependency Injection

```dart
// lib/core/di/injection.dart
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies() async {
  getIt.init();
}
```

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection.dart';
import 'features/media/presentation/bloc/media_bloc.dart';
import 'features/media/presentation/pages/camera_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<MediaBloc>()),
      ],
      child: MaterialApp(
        title: 'Camera & Media',
        theme: ThemeData(colorSchemeSeed: Colors.blue),
        home: const CameraPage(),
      ),
    );
  }
}
```

---

## 13. 테스트

### 13.1 Mock Repository

```dart
// test/features/media/mocks.dart
import 'package:mocktail/mocktail.dart';
import 'package:camera_media_example/features/media/domain/repositories/media_repository.dart';

class MockMediaRepository extends Mock implements MediaRepository {}

class FakeImageSource extends Fake implements ImageSource {}
```

### 13.2 UseCase 테스트

```dart
// test/features/media/domain/usecases/pick_image_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:camera_media_example/features/media/domain/usecases/pick_image.dart';
import 'package:camera_media_example/features/media/domain/entities/media_file.dart';
import '../../mocks.dart';

void main() {
  late PickImage usecase;
  late MockMediaRepository mockRepository;

  setUp(() {
    mockRepository = MockMediaRepository();
    usecase = PickImage(mockRepository);
    registerFallbackValue(FakeImageSource());
  });

  group('PickImage', () {
    final tMediaFile = MediaFile(
      path: '/test/image.jpg',
      type: MediaType.image,
      size: 1024,
      createdAt: DateTime.now(),
    );

    test('should return MediaFile when picking from gallery succeeds', () async {
      // arrange
      when(() => mockRepository.pickImage(
            source: any(named: 'source'),
            imageQuality: any(named: 'imageQuality'),
          )).thenAnswer((_) async => Right(tMediaFile));

      // act
      final result = await usecase(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      // assert
      expect(result, Right(tMediaFile));
      verify(() => mockRepository.pickImage(
            source: ImageSource.gallery,
            imageQuality: 85,
          )).called(1);
    });

    test('should return Failure when picking fails', () async {
      // arrange
      when(() => mockRepository.pickImage(
            source: any(named: 'source'),
          )).thenAnswer((_) async => const Left(MediaFailure('Error')));

      // act
      final result = await usecase(source: ImageSource.gallery);

      // assert
      expect(result.isLeft(), true);
    });
  });
}
```

### 13.3 Bloc 테스트

```dart
// test/features/media/presentation/bloc/media_bloc_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:camera_media_example/features/media/presentation/bloc/media_bloc.dart';
import 'package:camera_media_example/features/media/domain/entities/media_file.dart';
import 'package:camera_media_example/features/media/domain/usecases/pick_image.dart';
import 'package:camera_media_example/features/media/domain/usecases/capture_photo.dart';
import '../../mocks.dart';

class MockPickImage extends Mock implements PickImage {}
class MockCapturePhoto extends Mock implements CapturePhoto {}

void main() {
  late MediaBloc bloc;
  late MockPickImage mockPickImage;
  late MockCapturePhoto mockCapturePhoto;

  setUp(() {
    mockPickImage = MockPickImage();
    mockCapturePhoto = MockCapturePhoto();
    bloc = MediaBloc(mockPickImage, mockCapturePhoto);
    registerFallbackValue(FakeImageSource());
  });

  tearDown(() {
    bloc.close();
  });

  group('MediaBloc', () {
    final tMediaFile = MediaFile(
      path: '/test/image.jpg',
      type: MediaType.image,
      size: 1024,
      createdAt: DateTime.now(),
    );

    test('initial state should be MediaState.initial', () {
      expect(bloc.state, const MediaState.initial());
    });

    blocTest<MediaBloc, MediaState>(
      'emits [loading, loaded] when pickImage succeeds',
      build: () {
        when(() => mockPickImage(
              source: any(named: 'source'),
              imageQuality: any(named: 'imageQuality'),
            )).thenAnswer((_) async => Right(tMediaFile));
        return bloc;
      },
      act: (bloc) => bloc.add(const MediaEvent.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      )),
      expect: () => [
        const MediaState.loading(),
        MediaState.loaded([tMediaFile]),
      ],
    );

    blocTest<MediaBloc, MediaState>(
      'emits [loading, error] when pickImage fails',
      build: () {
        when(() => mockPickImage(
              source: any(named: 'source'),
            )).thenAnswer((_) async => const Left(MediaFailure('Error')));
        return bloc;
      },
      act: (bloc) => bloc.add(const MediaEvent.pickImage(
        source: ImageSource.gallery,
      )),
      expect: () => [
        const MediaState.loading(),
        const MediaState.error('Error'),
      ],
    );
  });
}
```

---

## 14. Best Practices

### 14.1 Do's

| 항목 | 설명 | 예시 |
|------|------|------|
| **권한 체크** | 사용 전 항상 권한 확인 | `permission_handler`로 사전 체크 |
| **메모리 관리** | Controller는 반드시 dispose | `dispose()` 메서드에서 정리 |
| **에러 처리** | 모든 카메라 작업은 try-catch | `CameraException` 처리 |
| **파일 정리** | 임시 파일은 사용 후 삭제 | `getTemporaryDirectory()` 활용 |
| **압축** | 네트워크 전송 전 압축 | `flutter_image_compress` 사용 |
| **비동기 처리** | 모든 미디어 작업은 async | `await` 키워드 사용 |

### 14.2 Don'ts

| 항목 | 피해야 할 이유 | 대안 |
|------|---------------|------|
| **권한 없이 접근** | 크래시 발생 | 사전 권한 체크 |
| **메모리 누수** | 앱 성능 저하 | Controller dispose |
| **대용량 파일** | 메모리 오버플로우 | 압축 후 처리 |
| **UI 스레드 차단** | ANR 발생 | compute() 사용 |
| **캐시 미정리** | 디스크 공간 부족 | 주기적 정리 |

### 14.3 권한 처리 패턴

```dart
// lib/core/utils/permission_utils.dart
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class PermissionUtils {
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.status;

    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    final result = await Permission.camera.request();
    return result.isGranted;
  }

  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await _getAndroidVersion() >= 33) {
        // Android 13+
        final photos = await Permission.photos.request();
        final videos = await Permission.videos.request();
        return photos.isGranted && videos.isGranted;
      } else {
        // Android 12 and below
        final storage = await Permission.storage.request();
        return storage.isGranted;
      }
    } else {
      final photos = await Permission.photos.request();
      return photos.isGranted;
    }
  }

  static Future<int> _getAndroidVersion() async {
    // Implement Android version check
    return 33;
  }
}
```

### 14.4 메모리 관리 패턴

```dart
// lib/features/media/presentation/pages/camera_page.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage>
    with WidgetsBindingObserver {
  CameraController? _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      // App is inactive, dispose camera
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // App is resumed, reinitialize camera
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    // Implementation
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera')),
      body: _controller?.value.isInitialized == true
          ? CameraPreview(_controller!)
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
```

### 14.5 에러 처리 패턴

```dart
// lib/core/error/error_handler.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class ErrorHandler {
  static void handleCameraError(
    BuildContext context,
    Object error,
  ) {
    String message;

    if (error is CameraException) {
      switch (error.code) {
        case 'CAMERA_ERROR':
          message = '카메라를 사용할 수 없습니다';
          break;
        case 'PERMISSION_DENIED':
          message = '카메라 권한이 거부되었습니다';
          break;
        case 'NOT_INITIALIZED':
          message = '카메라 초기화 실패';
          break;
        default:
          message = '알 수 없는 오류: ${error.description}';
      }
    } else {
      message = '오류가 발생했습니다: $error';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: '설정',
          textColor: Colors.white,
          onPressed: () {
            // Open settings if needed
          },
        ),
      ),
    );
  }
}
```

---

## 마치며

이 가이드는 Flutter에서 카메라 및 미디어 관련 기능을 Clean Architecture와 Bloc 패턴으로 구현하는 방법을 다룹니다. camera, image_picker, video_player, mobile_scanner 등의 패키지를 활용하여 실무에서 바로 적용 가능한 예제를 제공했습니다.

**핵심 포인트**
- 권한 처리를 항상 먼저 수행
- Controller는 반드시 dispose하여 메모리 누수 방지
- 대용량 파일은 압축 후 처리
- Clean Architecture로 테스트 가능한 구조 유지
- Bloc으로 상태 관리를 명확하게 분리

## 실습 과제

### 과제 1: 커스텀 카메라 촬영 화면
camera 패키지를 사용하여 전/후면 카메라 전환, 줌 슬라이더, 플래시 토글, 탭 포커스 기능이 포함된 커스텀 카메라 화면을 구현하세요. 촬영된 사진은 미리보기 화면에서 확인할 수 있어야 합니다.

### 과제 2: 이미지 피커 + 크롭 + 압축 파이프라인
image_picker로 갤러리에서 여러 장을 선택하고, image_cropper로 크롭한 후, flutter_image_compress로 85% 품질로 압축하는 전체 파이프라인을 구현하세요. 원본/압축 파일 크기를 비교 표시하세요.

### 과제 3: QR 코드 스캐너
mobile_scanner를 사용하여 QR 코드를 스캔하고, 스캔 결과가 URL이면 브라우저로 열기, 텍스트면 클립보드에 복사하는 분기 처리를 구현하세요. 스캔 오버레이 UI를 포함해야 합니다.

## Self-Check 퀴즈

- [ ] `WidgetsBindingObserver`를 사용하여 앱이 Background로 갈 때 카메라를 dispose하고, 복귀 시 재초기화하는 이유를 설명할 수 있는가?
- [ ] image_picker와 camera 패키지의 차이점과 각각의 적절한 사용 시점을 설명할 수 있는가?
- [ ] 대용량 이미지를 서버에 업로드하기 전 압축이 필요한 이유와 적절한 품질(quality) 값을 결정하는 기준을 이해하고 있는가?
- [ ] Android 13+ 에서 `READ_MEDIA_IMAGES` 권한이 `READ_EXTERNAL_STORAGE` 대신 필요한 이유를 설명할 수 있는가?
- [ ] video_player의 Controller를 dispose하지 않을 때 발생할 수 있는 문제를 메모리와 리소스 관점에서 설명할 수 있는가?

## 체크리스트

- [ ] camera, image_picker, video_player, mobile_scanner 패키지 설치
- [ ] Android/iOS 카메라, 마이크, 저장소 권한 설정
- [ ] CameraDataSource 및 MediaDataSource 구현
- [ ] MediaRepository 인터페이스 및 구현체 작성
- [ ] CameraBloc / MediaBloc / VideoBloc 구현
- [ ] 커스텀 카메라 UI (프리뷰, 컨트롤, 줌/포커스) 구현
- [ ] 이미지 피커 (단일/복수 선택) 구현
- [ ] 비디오 재생 위젯 (플레이어 컨트롤) 구현
- [ ] QR/바코드 스캐너 구현 (필요시)
- [ ] 이미지 크롭/압축 유틸리티 구현
- [ ] 메모리 관리 (Controller dispose, AppLifecycle 처리)

추가 학습 자료:
- [camera package 공식 문서](https://pub.dev/packages/camera)
- [image_picker 공식 문서](https://pub.dev/packages/image_picker)
- [video_player 공식 문서](https://pub.dev/packages/video_player)
- [mobile_scanner 공식 문서](https://pub.dev/packages/mobile_scanner)
