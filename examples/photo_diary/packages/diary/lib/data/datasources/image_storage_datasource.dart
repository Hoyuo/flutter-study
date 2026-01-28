import 'dart:io';

/// Data source interface for image storage operations
abstract class ImageStorageDataSource {
  /// Upload an image file to storage
  /// [userId] - ID of the user uploading the image
  /// [diaryId] - ID of the diary entry the image belongs to
  /// [imageFile] - The image file to upload
  /// [fileName] - Optional custom file name
  /// Returns the download URL of the uploaded image
  /// Throws [Exception] on error
  Future<String> uploadImage({
    required String userId,
    required String diaryId,
    required File imageFile,
    String? fileName,
  });

  /// Delete an image from storage
  /// [imageUrl] - The full download URL of the image to delete
  /// Throws [Exception] on error
  Future<void> deleteImage(String imageUrl);

  /// Delete all images for a diary entry
  /// [userId] - ID of the user who owns the images
  /// [diaryId] - ID of the diary entry whose images to delete
  /// Throws [Exception] on error
  Future<void> deleteAllImagesForDiary({
    required String userId,
    required String diaryId,
  });

  /// Get the storage path for a diary's images
  /// [userId] - ID of the user
  /// [diaryId] - ID of the diary entry
  /// Returns the storage path string
  String getDiaryImagesPath({
    required String userId,
    required String diaryId,
  });
}
