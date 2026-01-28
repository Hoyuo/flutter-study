# Flutter 이미지 처리 가이드

## 개요

이미지 캐싱(cached_network_image), 이미지 선택(image_picker), 이미지 크롭(image_cropper), 이미지 압축 및 서버 업로드 패턴을 다룹니다.

## 설치 및 설정

### 의존성 추가

```yaml
# pubspec.yaml
dependencies:
  cached_network_image: ^3.4.1
  image_picker: ^1.0.0
  image_cropper: ^8.0.0  # 2026년 1월 기준 최신 버전
  flutter_image_compress: ^2.1.0
  http_parser: ^4.0.0  # multipart 업로드용
  shimmer: ^3.0.0
  permission_handler: ^12.0.1  # 2026년 1월 기준 최신 버전
  path: ^1.8.0  # 경로 처리용
  device_info_plus: ^12.3.0  # 2026년 1월 기준 최신 버전
```

**주요 변경사항 (v5 → v8):**
- `image_cropper` ^8.0.0: API 변경 없음, 내부 구현 개선 및 최신 플랫폼 지원
- `device_info_plus` ^12.3.0: 최신 Android/iOS 기기 정보 지원, API 호환성 유지

### iOS 설정

```xml
<!-- ios/Runner/Info.plist -->
<key>NSPhotoLibraryUsageDescription</key>
<string>프로필 사진을 선택하기 위해 사진 라이브러리 접근이 필요합니다.</string>

<key>NSCameraUsageDescription</key>
<string>프로필 사진을 촬영하기 위해 카메라 접근이 필요합니다.</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>사진을 저장하기 위해 사진 라이브러리 접근이 필요합니다.</string>
```

### Android 설정

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest>
    <!-- 카메라 -->
    <uses-permission android:name="android.permission.CAMERA"/>

    <!-- 저장소 (Android 12 이하) -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
        android:maxSdkVersion="32"/>

    <!-- 사진 (Android 13+) -->
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>

    <application>
        <!-- image_cropper UCrop Activity -->
        <activity
            android:name="com.yalantis.ucrop.UCropActivity"
            android:screenOrientation="portrait"
            android:theme="@style/Theme.AppCompat.Light.NoActionBar"/>
    </application>
</manifest>
```

## 이미지 캐싱 (cached_network_image)

### 기본 사용

```dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class NetworkImageWidget extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const NetworkImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(),
      ),
      errorWidget: (context, url, error) => const Icon(
        Icons.error_outline,
        color: Colors.grey,
      ),
    );
  }
}
```

### 커스텀 플레이스홀더

```dart
CachedNetworkImage(
  imageUrl: imageUrl,
  placeholder: (context, url) => Container(
    color: Colors.grey[200],
    child: const Center(
      child: Icon(Icons.image, color: Colors.grey),
    ),
  ),
  errorWidget: (context, url, error) => Container(
    color: Colors.grey[200],
    child: const Center(
      child: Icon(Icons.broken_image, color: Colors.grey),
    ),
  ),
)
```

### Shimmer 로딩 효과

```dart
import 'package:shimmer/shimmer.dart';

CachedNetworkImage(
  imageUrl: imageUrl,
  placeholder: (context, url) => Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: Container(
      color: Colors.white,
      width: double.infinity,
      height: double.infinity,
    ),
  ),
)
```

### 원형 프로필 이미지

```dart
class CircleProfileImage extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final String? fallbackInitial;

  const CircleProfileImage({
    super.key,
    this.imageUrl,
    required this.radius,
    this.fallbackInitial,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[300],
        child: Text(
          fallbackInitial ?? '?',
          style: TextStyle(
            fontSize: radius * 0.8,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: radius,
        backgroundImage: imageProvider,
      ),
      placeholder: (context, url) => CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[300],
        child: const CircularProgressIndicator(strokeWidth: 2),
      ),
      errorWidget: (context, url, error) => CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[300],
        child: Text(fallbackInitial ?? '?'),
      ),
    );
  }
}
```

### 캐시 설정 커스터마이징

```dart
CachedNetworkImage(
  imageUrl: imageUrl,
  cacheKey: 'custom_cache_key_$imageUrl',  // 커스텀 캐시 키
  maxWidthDiskCache: 500,  // 디스크 캐시 최대 너비
  maxHeightDiskCache: 500,  // 디스크 캐시 최대 높이
  memCacheWidth: 200,  // 메모리 캐시 너비
  memCacheHeight: 200,  // 메모리 캐시 높이
)
```

### 캐시 삭제

```dart
import 'package:cached_network_image/cached_network_image.dart';

// 특정 이미지 캐시 삭제
await CachedNetworkImage.evictFromCache(imageUrl);

// 전체 캐시 삭제
await DefaultCacheManager().emptyCache();
```

## 이미지 선택 (image_picker)

### Image Picker Service

```dart
// lib/core/image/image_picker_service.dart
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart';

enum ImageSourceType { camera, gallery }

@lazySingleton
class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  /// 카메라/갤러리 권한 요청
  Future<bool> _requestPermission(ImageSourceType source) async {
    Permission permission;

    if (source == ImageSourceType.camera) {
      permission = Permission.camera;
    } else {
      // Android 13+ 분기 처리
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt >= 33) {
          permission = Permission.photos;
        } else {
          permission = Permission.storage;
        }
      } else {
        permission = Permission.photos;
      }
    }

    final status = await permission.request();

    if (status.isDenied) {
      // 사용자에게 권한 필요 안내
      return false;
    }

    if (status.isPermanentlyDenied) {
      // 설정 앱으로 이동 안내
      await openAppSettings();
      return false;
    }

    return status.isGranted;
  }

  /// 단일 이미지 선택 (권한 체크 포함)
  Future<File?> pickImage({
    required ImageSourceType source,
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
  }) async {
    // 권한 확인
    final hasPermission = await _requestPermission(source);
    if (!hasPermission) return null;

    final XFile? pickedFile = await _picker.pickImage(
      source: source == ImageSourceType.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: maxWidth?.toDouble(),
      maxHeight: maxHeight?.toDouble(),
      imageQuality: imageQuality ?? 80,
    );

    if (pickedFile == null) return null;
    return File(pickedFile.path);
  }

  /// 여러 이미지 선택 (갤러리만, 권한 체크 포함)
  Future<List<File>> pickMultipleImages({
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
    int? limit,
  }) async {
    // 권한 확인
    final hasPermission = await _requestPermission(ImageSourceType.gallery);
    if (!hasPermission) return [];

    final List<XFile> pickedFiles = await _picker.pickMultiImage(
      maxWidth: maxWidth?.toDouble(),
      maxHeight: maxHeight?.toDouble(),
      imageQuality: imageQuality ?? 80,
      limit: limit,
    );

    return pickedFiles.map((xFile) => File(xFile.path)).toList();
  }

  /// 비디오 선택
  Future<File?> pickVideo({
    required ImageSourceType source,
    Duration? maxDuration,
  }) async {
    final XFile? pickedFile = await _picker.pickVideo(
      source: source == ImageSourceType.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxDuration: maxDuration,
    );

    if (pickedFile == null) return null;
    return File(pickedFile.path);
  }
}
```

### 이미지 소스 선택 다이얼로그

```dart
// lib/core/image/image_source_dialog.dart
import 'package:flutter/material.dart';

Future<ImageSourceType?> showImageSourceDialog(BuildContext context) async {
  return showModalBottomSheet<ImageSourceType>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('카메라로 촬영'),
              onTap: () => Navigator.pop(context, ImageSourceType.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('갤러리에서 선택'),
              onTap: () => Navigator.pop(context, ImageSourceType.gallery),
            ),
          ],
        ),
      ),
    ),
  );
}
```

## 이미지 크롭 (image_cropper)

### Image Cropper Service

```dart
// lib/core/image/image_cropper_service.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class ImageCropperService {
  /// 이미지 크롭
  Future<File?> cropImage({
    required File imageFile,
    CropAspectRatio? aspectRatio,
    List<CropAspectRatioPreset>? aspectRatioPresets,
    CropStyle cropStyle = CropStyle.rectangle,
    int? maxWidth,
    int? maxHeight,
    int? compressQuality,
  }) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      aspectRatio: aspectRatio,
      aspectRatioPresets: aspectRatioPresets ??
          [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ],
      cropStyle: cropStyle,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      compressQuality: compressQuality ?? 90,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '이미지 편집',
          toolbarColor: Colors.blue,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: aspectRatio != null,
          hideBottomControls: false,
        ),
        IOSUiSettings(
          title: '이미지 편집',
          doneButtonTitle: '완료',
          cancelButtonTitle: '취소',
          aspectRatioLockEnabled: aspectRatio != null,
        ),
      ],
    );

    if (croppedFile == null) return null;
    return File(croppedFile.path);
  }

  /// 프로필 이미지용 (정사각형)
  Future<File?> cropProfileImage(File imageFile) async {
    return cropImage(
      imageFile: imageFile,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      cropStyle: CropStyle.circle,
      maxWidth: 500,
      maxHeight: 500,
      compressQuality: 85,
    );
  }

  /// 배너 이미지용 (16:9)
  Future<File?> cropBannerImage(File imageFile) async {
    return cropImage(
      imageFile: imageFile,
      aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9),
      maxWidth: 1920,
      maxHeight: 1080,
      compressQuality: 90,
    );
  }
}
```

## 이미지 압축

### Image Compress Service

```dart
// lib/core/image/image_compress_service.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';

@lazySingleton
class ImageCompressService {
  /// 파일 압축
  Future<File?> compressFile({
    required File file,
    int quality = 80,
    int? minWidth,
    int? minHeight,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final targetPath =
        '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      file.path,
      targetPath,
      quality: quality,
      minWidth: minWidth ?? 1024,
      minHeight: minHeight ?? 1024,
      format: CompressFormat.jpeg,
    );

    if (result == null) return null;
    return File(result.path);
  }

  /// 바이트 배열로 압축
  Future<Uint8List?> compressFileToBytes({
    required File file,
    int quality = 80,
    int? minWidth,
    int? minHeight,
  }) async {
    return FlutterImageCompress.compressWithFile(
      file.path,
      quality: quality,
      minWidth: minWidth ?? 1024,
      minHeight: minHeight ?? 1024,
      format: CompressFormat.jpeg,
    );
  }

  /// 업로드용 압축 (최대 용량 제한)
  Future<File?> compressForUpload({
    required File file,
    int maxSizeKB = 500,
  }) async {
    final fileSize = await file.length();
    final fileSizeKB = fileSize / 1024;

    if (fileSizeKB <= maxSizeKB) {
      // 이미 작은 경우 그대로 반환
      return file;
    }

    // 압축 품질 계산 (대략적)
    int quality = ((maxSizeKB / fileSizeKB) * 100).round().clamp(20, 95);

    return compressFile(file: file, quality: quality);
  }
}
```

## 임시 파일 정리

### File Cleanup Utility

```dart
// lib/core/image/file_cleanup_utility.dart
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as path;

@lazySingleton
class FileCleanupUtility {
  /// 처리 완료 후 임시 파일 정리
  Future<void> cleanupTempFiles(List<String> paths) async {
    for (final filePath in paths) {
      try {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // 삭제 실패 무시 (이미 삭제되었거나 권한 문제)
        print('Failed to delete temp file: $filePath - $e');
      }
    }
  }

  /// 특정 디렉토리의 오래된 임시 파일 정리
  Future<void> cleanupOldTempFiles({
    required String directoryPath,
    Duration maxAge = const Duration(days: 1),
  }) async {
    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) return;

      final now = DateTime.now();
      final entities = directory.listSync();

      for (final entity in entities) {
        if (entity is File) {
          final stat = await entity.stat();
          final age = now.difference(stat.modified);

          if (age > maxAge) {
            try {
              await entity.delete();
            } catch (e) {
              print('Failed to delete old file: ${entity.path} - $e');
            }
          }
        }
      }
    } catch (e) {
      print('Failed to cleanup old temp files: $e');
    }
  }

  /// 앱 캐시 디렉토리 전체 정리
  Future<void> clearAllCache() async {
    try {
      // 플랫폼별 캐시 디렉토리 정리는 path_provider 사용
      // 여기서는 예시만 제공
      print('Cache cleared successfully');
    } catch (e) {
      print('Failed to clear cache: $e');
    }
  }
}
```

### 사용 예시

```dart
// 이미지 처리 후 임시 파일 정리
final tempPaths = <String>[];

// 1. 이미지 선택
final pickedFile = await imagePickerService.pickImage(...);
if (pickedFile != null) {
  tempPaths.add(pickedFile.path);

  // 2. 크롭
  final croppedFile = await imageCropperService.cropImage(...);
  if (croppedFile != null) {
    tempPaths.add(croppedFile.path);

    // 3. 압축
    final compressedFile = await imageCompressService.compressFile(...);
    if (compressedFile != null) {
      tempPaths.add(compressedFile.path);

      // 4. 업로드
      final url = await imageUploadService.uploadImage(...);

      // 5. 성공 후 임시 파일 정리
      await fileCleanupUtility.cleanupTempFiles(tempPaths);
    }
  }
}
```

## 이미지 업로드

### Image Upload Service

```dart
// lib/core/image/image_upload_service.dart
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:injectable/injectable.dart';

import '../network/dio_client.dart';

@lazySingleton
class ImageUploadService {
  final DioClient _dioClient;

  ImageUploadService(this._dioClient);

  /// 단일 이미지 업로드
  Future<String> uploadImage({
    required File file,
    required String uploadPath,
    String fieldName = 'file',
    Map<String, dynamic>? additionalData,
    void Function(int sent, int total)? onProgress,
  }) async {
    final fileName = file.path.split('/').last;
    final extension = fileName.split('.').last.toLowerCase();

    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(
        file.path,
        filename: fileName,
        contentType: MediaType('image', extension),
      ),
      ...?additionalData,
    });

    final response = await _dioClient.post(
      uploadPath,
      data: formData,
      options: Options(
        headers: {'Content-Type': 'multipart/form-data'},
      ),
      onSendProgress: onProgress,
    );

    // 서버 응답에서 이미지 URL 추출 (서버 구현에 따라 다름)
    return response.data['url'] as String;
  }

  /// 여러 이미지 업로드
  Future<List<String>> uploadMultipleImages({
    required List<File> files,
    required String uploadPath,
    String fieldName = 'files',
    void Function(int sent, int total)? onProgress,
  }) async {
    final multipartFiles = await Future.wait(
      files.map((file) async {
        final fileName = file.path.split('/').last;
        final extension = fileName.split('.').last.toLowerCase();
        return MultipartFile.fromFile(
          file.path,
          filename: fileName,
          contentType: MediaType('image', extension),
        );
      }),
    );

    final formData = FormData.fromMap({
      fieldName: multipartFiles,
    });

    final response = await _dioClient.post(
      uploadPath,
      data: formData,
      options: Options(
        headers: {'Content-Type': 'multipart/form-data'},
      ),
      onSendProgress: onProgress,
    );

    return (response.data['urls'] as List).cast<String>();
  }
}
```

## 통합 Image Service

### 전체 워크플로우 통합

```dart
// lib/core/image/image_service.dart
import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../error/failure.dart';
import 'image_compress_service.dart';
import 'image_cropper_service.dart';
import 'image_picker_service.dart';
import 'image_upload_service.dart';

@lazySingleton
class ImageService {
  final ImagePickerService _pickerService;
  final ImageCropperService _cropperService;
  final ImageCompressService _compressService;
  final ImageUploadService _uploadService;

  ImageService(
    this._pickerService,
    this._cropperService,
    this._compressService,
    this._uploadService,
  );

  /// 프로필 이미지 선택 → 크롭 → 압축 → 업로드
  Future<Either<Failure, String>> pickAndUploadProfileImage({
    required ImageSourceType source,
    required String uploadPath,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      // 1. 이미지 선택
      final pickedFile = await _pickerService.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
      );

      if (pickedFile == null) {
        return const Left(Failure.cancelled(message: '이미지 선택이 취소되었습니다'));
      }

      // 2. 크롭 (정사각형)
      final croppedFile = await _cropperService.cropProfileImage(pickedFile);

      if (croppedFile == null) {
        return const Left(Failure.cancelled(message: '이미지 편집이 취소되었습니다'));
      }

      // 3. 압축
      final compressedFile = await _compressService.compressForUpload(
        file: croppedFile,
        maxSizeKB: 300,
      );

      if (compressedFile == null) {
        return const Left(Failure.unknown(message: '이미지 압축에 실패했습니다'));
      }

      // 4. 업로드
      final imageUrl = await _uploadService.uploadImage(
        file: compressedFile,
        uploadPath: uploadPath,
        onProgress: onProgress,
      );

      return Right(imageUrl);
    } catch (e) {
      return Left(Failure.unknown(message: e.toString()));
    }
  }

  /// 상품 이미지 선택 (여러 장)
  Future<Either<Failure, List<String>>> pickAndUploadProductImages({
    required int maxImages,
    required String uploadPath,
    void Function(int current, int total)? onImageProgress,
  }) async {
    try {
      // 1. 여러 이미지 선택
      final pickedFiles = await _pickerService.pickMultipleImages(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
        limit: maxImages,
      );

      if (pickedFiles.isEmpty) {
        return const Left(Failure.cancelled(message: '이미지 선택이 취소되었습니다'));
      }

      // 2. 각 이미지 압축 및 업로드
      final uploadedUrls = <String>[];

      for (int i = 0; i < pickedFiles.length; i++) {
        onImageProgress?.call(i + 1, pickedFiles.length);

        final compressedFile = await _compressService.compressForUpload(
          file: pickedFiles[i],
          maxSizeKB: 500,
        );

        if (compressedFile != null) {
          final url = await _uploadService.uploadImage(
            file: compressedFile,
            uploadPath: uploadPath,
          );
          uploadedUrls.add(url);
        }
      }

      return Right(uploadedUrls);
    } catch (e) {
      return Left(Failure.unknown(message: e.toString()));
    }
  }
}
```

## Bloc 통합

### Image Picker Bloc

```dart
// lib/features/profile/presentation/bloc/image_picker_event.dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/image/image_picker_service.dart';

part 'image_picker_event.freezed.dart';

@freezed
class ImagePickerEvent with _$ImagePickerEvent {
  const factory ImagePickerEvent.picked(ImageSourceType source) = _Picked;
  const factory ImagePickerEvent.cleared() = _Cleared;
}
```

```dart
// lib/features/profile/presentation/bloc/image_picker_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'image_picker_state.freezed.dart';

@freezed
class ImagePickerState with _$ImagePickerState {
  const factory ImagePickerState({
    String? imageUrl,
    required bool isLoading,
    required double uploadProgress,
    String? error,
  }) = _ImagePickerState;

  factory ImagePickerState.initial() => const ImagePickerState(
        isLoading: false,
        uploadProgress: 0,
      );
}
```

```dart
// lib/features/profile/presentation/bloc/image_picker_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/image/image_service.dart';
import 'image_picker_event.dart';
import 'image_picker_state.dart';

class ImagePickerBloc extends Bloc<ImagePickerEvent, ImagePickerState> {
  final ImageService _imageService;

  ImagePickerBloc({required ImageService imageService})
      : _imageService = imageService,
        super(ImagePickerState.initial()) {
    on<ImagePickerEvent>((event, emit) async {
      await event.when(
        picked: (source) => _onPicked(source, emit),
        cleared: () => _onCleared(emit),
      );
    });
  }

  Future<void> _onPicked(
    ImageSourceType source,
    Emitter<ImagePickerState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null, uploadProgress: 0));

    final result = await _imageService.pickAndUploadProfileImage(
      source: source,
      uploadPath: '/api/upload/profile',
      onProgress: (sent, total) {
        final progress = sent / total;
        emit(state.copyWith(uploadProgress: progress));
      },
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        error: failure.message,
      )),
      (imageUrl) => emit(state.copyWith(
        isLoading: false,
        imageUrl: imageUrl,
        uploadProgress: 1.0,
      )),
    );
  }

  Future<void> _onCleared(Emitter<ImagePickerState> emit) async {
    emit(ImagePickerState.initial());
  }
}
```

## UI 컴포넌트

### 프로필 이미지 편집 위젯

```dart
class ProfileImageEditor extends StatelessWidget {
  final String? currentImageUrl;
  final VoidCallback? onImageChanged;

  const ProfileImageEditor({
    super.key,
    this.currentImageUrl,
    this.onImageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ImagePickerBloc, ImagePickerState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!)),
          );
        }
        if (state.imageUrl != null && !state.isLoading) {
          onImageChanged?.call();
        }
      },
      builder: (context, state) {
        return GestureDetector(
          onTap: state.isLoading ? null : () => _showImagePicker(context),
          child: Stack(
            children: [
              // 프로필 이미지
              CircleProfileImage(
                imageUrl: state.imageUrl ?? currentImageUrl,
                radius: 50,
                fallbackInitial: 'U',
              ),

              // 로딩 오버레이
              if (state.isLoading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        value: state.uploadProgress > 0
                            ? state.uploadProgress
                            : null,
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                ),

              // 편집 아이콘
              if (!state.isLoading)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showImagePicker(BuildContext context) async {
    final source = await showImageSourceDialog(context);
    if (source != null) {
      context.read<ImagePickerBloc>().add(ImagePickerEvent.picked(source));
    }
  }
}
```

### 이미지 그리드 (여러 이미지)

```dart
class ImageGridPicker extends StatelessWidget {
  final List<String> images;
  final int maxImages;
  final void Function(List<String>) onImagesChanged;

  const ImageGridPicker({
    super.key,
    required this.images,
    required this.maxImages,
    required this.onImagesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: images.length + (images.length < maxImages ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == images.length) {
          // 추가 버튼
          return _AddImageButton(
            onTap: () => _addImage(context),
          );
        }

        // 이미지 타일
        return _ImageTile(
          imageUrl: images[index],
          onRemove: () => _removeImage(index),
        );
      },
    );
  }

  void _addImage(BuildContext context) async {
    // 이미지 선택 로직
  }

  void _removeImage(int index) {
    final newImages = [...images];
    newImages.removeAt(index);
    onImagesChanged(newImages);
  }
}

class _AddImageButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddImageButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[400]!, style: BorderStyle.solid),
        ),
        child: const Center(
          child: Icon(Icons.add_a_photo, color: Colors.grey, size: 32),
        ),
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onRemove;

  const _ImageTile({
    required this.imageUrl,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
```

## 체크리스트

- [ ] cached_network_image, image_picker, image_cropper, flutter_image_compress, permission_handler 설치
- [ ] iOS Info.plist 권한 설명 추가
- [ ] Android AndroidManifest.xml 권한 및 UCropActivity 추가 (maxSdkVersion="32" 포함)
- [ ] ImagePickerService 구현 (권한 처리 포함)
- [ ] ImageCropperService 구현 (프로필용, 배너용 등)
- [ ] ImageCompressService 구현
- [ ] ImageUploadService 구현 (Multipart)
- [ ] FileCleanupUtility 구현 (임시 파일 정리)
- [ ] 통합 ImageService 구현
- [ ] 권한 요청 흐름 테스트 (카메라, 갤러리)
- [ ] Android 13+ 권한 분기 처리 테스트
- [ ] 이미지 캐시 위젯 (NetworkImageWidget, CircleProfileImage)
- [ ] 이미지 선택 다이얼로그
- [ ] 업로드 진행률 표시 UI
- [ ] 여러 이미지 그리드 UI (필요시)
- [ ] 임시 파일 정리 로직 적용
