part of 'image_upload_bloc.dart';

/// 이미지 업로드 상태
@freezed
class ImageUploadState with _$ImageUploadState {
  /// 초기 상태
  const factory ImageUploadState.initial() = _Initial;

  /// 이미지 선택 중
  const factory ImageUploadState.picking() = _Picking;

  /// 이미지 압축 중
  const factory ImageUploadState.compressing({
    required int current,
    required int total,
  }) = _Compressing;

  /// 이미지 업로드 중
  const factory ImageUploadState.uploading({
    required int current,
    required int total,
    required double progress,
  }) = _Uploading;

  /// 업로드 성공
  const factory ImageUploadState.success({required List<String> imageUrls}) =
      _Success;

  /// 업로드 실패
  const factory ImageUploadState.failure({required String message}) = _Failure;

  /// 업로드 취소됨
  const factory ImageUploadState.cancelled() = _Cancelled;
}
