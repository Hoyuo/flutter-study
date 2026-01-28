import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'image_storage_datasource.dart';

/// Firebase Storage implementation of image storage data source
class FirebaseStorageImageDataSource implements ImageStorageDataSource {
  final FirebaseStorage _storage;

  FirebaseStorageImageDataSource({
    FirebaseStorage? storage,
  }) : _storage = storage ?? FirebaseStorage.instance;

  @override
  String getDiaryImagesPath({
    required String userId,
    required String diaryId,
  }) {
    return 'users/$userId/diaries/$diaryId/images';
  }

  @override
  Future<String> uploadImage({
    required String userId,
    required String diaryId,
    required File imageFile,
    String? fileName,
  }) async {
    try {
      // Generate file name if not provided
      final name = fileName ??
          '${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';

      // Create storage reference
      final storagePath =
          '${getDiaryImagesPath(userId: userId, diaryId: diaryId)}/$name';
      final ref = _storage.ref().child(storagePath);

      // Upload file
      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: _getContentType(imageFile.path),
          customMetadata: {
            'userId': userId,
            'diaryId': diaryId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Wait for upload to complete
      final snapshot = await uploadTask.whenComplete(() => null);

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  @override
  Future<void> deleteImage(String imageUrl) async {
    try {
      // Extract storage path from download URL
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }

  @override
  Future<void> deleteAllImagesForDiary({
    required String userId,
    required String diaryId,
  }) async {
    try {
      final storagePath = getDiaryImagesPath(userId: userId, diaryId: diaryId);
      final ref = _storage.ref().child(storagePath);

      // List all files in the directory
      final listResult = await ref.listAll();

      // Delete each file
      final deleteOperations = listResult.items.map((item) => item.delete());
      await Future.wait(deleteOperations);
    } catch (e) {
      throw Exception('Failed to delete all images for diary: $e');
    }
  }

  /// Get content type based on file extension
  String _getContentType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.heic':
        return 'image/heic';
      default:
        return 'application/octet-stream';
    }
  }
}
