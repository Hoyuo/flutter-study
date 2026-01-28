import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';

import 'image_service.dart';

/// 이미지 서비스 구현체
///
/// image_picker와 flutter_image_compress를 사용하여
/// 이미지 선택 및 압축 기능을 구현합니다.
@LazySingleton(as: ImageService)
class ImageServiceImpl implements ImageService {
  final ImagePicker _imagePicker;

  ImageServiceImpl() : _imagePicker = ImagePicker();

  @override
  Future<File?> pickFromCamera({int maxWidth = 1080, int quality = 85}) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: maxWidth.toDouble(),
        imageQuality: quality,
      );
      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      // 에러 발생 시 null 반환 (사용자가 권한을 거부하거나 기타 에러)
      return null;
    }
  }

  @override
  Future<File?> pickFromGallery({
    int maxWidth = 1080,
    int quality = 85,
  }) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth.toDouble(),
        imageQuality: quality,
      );
      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      // 에러 발생 시 null 반환
      return null;
    }
  }

  @override
  Future<List<File>> pickMultipleFromGallery({
    int maxWidth = 1080,
    int quality = 85,
    int limit = 10,
  }) async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: maxWidth.toDouble(),
        imageQuality: quality,
        limit: limit,
      );
      return images.map((xFile) => File(xFile.path)).toList();
    } catch (e) {
      // 에러 발생 시 빈 리스트 반환
      return [];
    }
  }

  @override
  Future<File?> compressImage(
    File file, {
    int maxWidth = 1080,
    int quality = 85,
  }) async {
    try {
      // 압축된 이미지를 임시 파일로 저장
      final String targetPath = file.path.replaceAll(
        RegExp(r'\.(jpg|jpeg|png|webp)$'),
        '_compressed.jpg',
      );

      final XFile? compressedFile =
          await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        minWidth: maxWidth,
        format: CompressFormat.jpeg,
      );

      if (compressedFile == null) return null;
      return File(compressedFile.path);
    } catch (e) {
      // 압축 실패 시 원본 파일 반환
      return file;
    }
  }

  @override
  Future<({int width, int height})?> getImageSize(File file) async {
    try {
      // 이미지 파일의 크기 정보 가져오기
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return (width: frame.image.width, height: frame.image.height);
    } catch (e) {
      // 에러 발생 시 null 반환
      return null;
    }
  }
}
