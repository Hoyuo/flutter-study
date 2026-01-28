import 'dart:io';

/// 이미지 서비스 인터페이스
///
/// 이미지 선택, 압축, 크기 확인 등의 기능을 제공합니다.
abstract class ImageService {
  /// 카메라로 사진 촬영
  ///
  /// [maxWidth] 최대 너비 (기본값: 1080)
  /// [quality] 이미지 품질 (0-100, 기본값: 85)
  /// Returns null if cancelled
  Future<File?> pickFromCamera({int maxWidth = 1080, int quality = 85});

  /// 갤러리에서 사진 선택
  ///
  /// [maxWidth] 최대 너비 (기본값: 1080)
  /// [quality] 이미지 품질 (0-100, 기본값: 85)
  /// Returns null if cancelled
  Future<File?> pickFromGallery({int maxWidth = 1080, int quality = 85});

  /// 여러 사진 선택
  ///
  /// [maxWidth] 최대 너비 (기본값: 1080)
  /// [quality] 이미지 품질 (0-100, 기본값: 85)
  /// [limit] 선택 가능한 최대 개수 (기본값: 10)
  /// Returns empty list if cancelled
  Future<List<File>> pickMultipleFromGallery({
    int maxWidth = 1080,
    int quality = 85,
    int limit = 10,
  });

  /// 이미지 압축
  ///
  /// [file] 압축할 이미지 파일
  /// [maxWidth] 최대 너비 (기본값: 1080)
  /// [quality] 이미지 품질 (0-100, 기본값: 85)
  /// Returns null on error
  Future<File?> compressImage(
    File file, {
    int maxWidth = 1080,
    int quality = 85,
  });

  /// 이미지 크기 가져오기
  ///
  /// [file] 크기를 확인할 이미지 파일
  /// Returns null on error
  Future<({int width, int height})?> getImageSize(File file);
}
