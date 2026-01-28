part of 'image_upload_bloc.dart';

/// 이미지 업로드 이벤트
@freezed
class ImageUploadEvent with _$ImageUploadEvent {
  /// 카메라에서 이미지 선택 및 업로드
  const factory ImageUploadEvent.pickFromCamera({
    required String userId,
    required String diaryId,
  }) = _PickFromCamera;

  /// 갤러리에서 이미지 선택 및 업로드
  const factory ImageUploadEvent.pickFromGallery({
    required String userId,
    required String diaryId,
  }) = _PickFromGallery;

  /// 여러 이미지 선택 및 업로드
  const factory ImageUploadEvent.pickMultipleFromGallery({
    required String userId,
    required String diaryId,
    @Default(10) int limit,
  }) = _PickMultipleFromGallery;

  /// 업로드 취소
  const factory ImageUploadEvent.cancelUpload() = _CancelUpload;
}
