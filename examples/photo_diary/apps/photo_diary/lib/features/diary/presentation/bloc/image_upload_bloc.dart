import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import 'package:core/core.dart';
import 'package:diary/diary.dart';

part 'image_upload_event.dart';
part 'image_upload_state.dart';
part 'image_upload_bloc.freezed.dart';

/// 이미지 업로드 Bloc
///
/// 이미지 선택, 압축, Firebase Storage 업로드를 처리합니다.
@injectable
class ImageUploadBloc extends Bloc<ImageUploadEvent, ImageUploadState> {
  final ImageService _imageService;
  final ImageStorageDataSource _imageStorage;

  ImageUploadBloc(this._imageService, this._imageStorage)
    : super(const ImageUploadState.initial()) {
    on<_PickFromCamera>(_onPickFromCamera);
    on<_PickFromGallery>(_onPickFromGallery);
    on<_PickMultipleFromGallery>(_onPickMultipleFromGallery);
    on<_CancelUpload>(_onCancelUpload);
  }

  /// 카메라에서 이미지 선택 및 업로드
  Future<void> _onPickFromCamera(
    _PickFromCamera event,
    Emitter<ImageUploadState> emit,
  ) async {
    emit(const ImageUploadState.picking());

    // 1. 카메라에서 이미지 선택
    final File? imageFile = await _imageService.pickFromCamera();
    if (imageFile == null) {
      emit(const ImageUploadState.cancelled());
      return;
    }

    // 2. 단일 이미지 처리 및 업로드
    await _processAndUploadSingleImage(
      imageFile: imageFile,
      userId: event.userId,
      diaryId: event.diaryId,
      emit: emit,
    );
  }

  /// 갤러리에서 이미지 선택 및 업로드
  Future<void> _onPickFromGallery(
    _PickFromGallery event,
    Emitter<ImageUploadState> emit,
  ) async {
    emit(const ImageUploadState.picking());

    // 1. 갤러리에서 이미지 선택
    final File? imageFile = await _imageService.pickFromGallery();
    if (imageFile == null) {
      emit(const ImageUploadState.cancelled());
      return;
    }

    // 2. 단일 이미지 처리 및 업로드
    await _processAndUploadSingleImage(
      imageFile: imageFile,
      userId: event.userId,
      diaryId: event.diaryId,
      emit: emit,
    );
  }

  /// 여러 이미지 선택 및 업로드
  Future<void> _onPickMultipleFromGallery(
    _PickMultipleFromGallery event,
    Emitter<ImageUploadState> emit,
  ) async {
    emit(const ImageUploadState.picking());

    // 1. 갤러리에서 여러 이미지 선택
    final List<File> imageFiles = await _imageService.pickMultipleFromGallery(
      limit: event.limit,
    );

    if (imageFiles.isEmpty) {
      emit(const ImageUploadState.cancelled());
      return;
    }

    // 2. 여러 이미지 처리 및 업로드
    await _processAndUploadMultipleImages(
      imageFiles: imageFiles,
      userId: event.userId,
      diaryId: event.diaryId,
      emit: emit,
    );
  }

  /// 업로드 취소
  Future<void> _onCancelUpload(
    _CancelUpload event,
    Emitter<ImageUploadState> emit,
  ) async {
    emit(const ImageUploadState.cancelled());
  }

  /// 단일 이미지 처리 및 업로드
  Future<void> _processAndUploadSingleImage({
    required File imageFile,
    required String userId,
    required String diaryId,
    required Emitter<ImageUploadState> emit,
  }) async {
    try {
      // 1. 이미지 압축
      emit(const ImageUploadState.compressing(current: 1, total: 1));

      final File? compressedFile = await _imageService.compressImage(
        imageFile,
        maxWidth: 1080,
        quality: 85,
      );

      if (compressedFile == null) {
        emit(const ImageUploadState.failure(message: '이미지 압축에 실패했습니다.'));
        return;
      }

      // 2. Firebase Storage에 업로드
      emit(
        const ImageUploadState.uploading(current: 1, total: 1, progress: 0.0),
      );

      final result = await TaskEither.tryCatch(
        () => _imageStorage.uploadImage(
          userId: userId,
          diaryId: diaryId,
          imageFile: compressedFile,
        ),
        (error, stackTrace) =>
            Failure.unknown(message: error.toString(), error: error),
      ).run();

      result.fold(
        (failure) => emit(ImageUploadState.failure(message: failure.message)),
        (imageUrl) => emit(ImageUploadState.success(imageUrls: [imageUrl])),
      );
    } catch (e) {
      emit(ImageUploadState.failure(message: e.toString()));
    }
  }

  /// 여러 이미지 처리 및 업로드
  Future<void> _processAndUploadMultipleImages({
    required List<File> imageFiles,
    required String userId,
    required String diaryId,
    required Emitter<ImageUploadState> emit,
  }) async {
    try {
      final List<String> uploadedUrls = [];
      final int total = imageFiles.length;

      // 1. 각 이미지 압축
      final List<File> compressedFiles = [];
      for (int i = 0; i < total; i++) {
        emit(ImageUploadState.compressing(current: i + 1, total: total));

        final File? compressedFile = await _imageService.compressImage(
          imageFiles[i],
          maxWidth: 1080,
          quality: 85,
        );

        if (compressedFile == null) {
          emit(ImageUploadState.failure(message: '이미지 ${i + 1} 압축에 실패했습니다.'));
          return;
        }

        compressedFiles.add(compressedFile);
      }

      // 2. 각 이미지 업로드
      for (int i = 0; i < compressedFiles.length; i++) {
        emit(
          ImageUploadState.uploading(
            current: i + 1,
            total: total,
            progress: (i / total) * 100,
          ),
        );

        final result = await TaskEither.tryCatch(
          () => _imageStorage.uploadImage(
            userId: userId,
            diaryId: diaryId,
            imageFile: compressedFiles[i],
          ),
          (error, stackTrace) =>
              Failure.unknown(message: error.toString(), error: error),
        ).run();

        final imageUrl = result.fold((failure) => null, (url) => url);

        if (imageUrl == null) {
          emit(ImageUploadState.failure(message: '이미지 ${i + 1} 업로드에 실패했습니다.'));
          return;
        }

        uploadedUrls.add(imageUrl);
      }

      // 3. 모든 업로드 성공
      emit(ImageUploadState.success(imageUrls: uploadedUrls));
    } catch (e) {
      emit(ImageUploadState.failure(message: e.toString()));
    }
  }
}
