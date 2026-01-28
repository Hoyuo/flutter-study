import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import 'diary_remote_datasource.dart';

/// Firestore implementation of diary remote data source
class FirestoreDiaryRemoteDataSource implements DiaryRemoteDataSource {
  final FirebaseFirestore _firestore;

  FirestoreDiaryRemoteDataSource({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get reference to user's diaries collection
  CollectionReference _getDiariesCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('diaries');
  }

  @override
  Future<DiaryEntryModel> createDiary(DiaryEntryModel entry) async {
    try {
      final collection = _getDiariesCollection(entry.userId);
      final docRef = await collection.add(entry.toFirestore());
      final doc = await docRef.get();
      return DiaryEntryModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to create diary: $e');
    }
  }

  @override
  Future<List<DiaryEntryModel>> getDiaries({
    required String userId,
    int limit = 20,
    String? startAfterDocId,
  }) async {
    try {
      final collection = _getDiariesCollection(userId);
      Query query =
          collection.orderBy('createdAt', descending: true).limit(limit);

      // Apply pagination if startAfterDocId is provided
      if (startAfterDocId != null) {
        final startAfterDoc = await collection.doc(startAfterDocId).get();
        if (startAfterDoc.exists) {
          query = query.startAfterDocument(startAfterDoc);
        }
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => DiaryEntryModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get diaries: $e');
    }
  }

  @override
  Future<DiaryEntryModel> getDiaryById({
    required String userId,
    required String diaryId,
  }) async {
    try {
      final doc = await _getDiariesCollection(userId).doc(diaryId).get();
      if (!doc.exists) {
        throw Exception('Diary not found');
      }
      return DiaryEntryModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get diary: $e');
    }
  }

  @override
  Future<DiaryEntryModel> updateDiary(DiaryEntryModel entry) async {
    try {
      final docRef = _getDiariesCollection(entry.userId).doc(entry.id);
      await docRef.update(entry.toFirestore());
      final doc = await docRef.get();
      return DiaryEntryModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to update diary: $e');
    }
  }

  @override
  Future<void> deleteDiary({
    required String userId,
    required String diaryId,
  }) async {
    try {
      await _getDiariesCollection(userId).doc(diaryId).delete();
    } catch (e) {
      throw Exception('Failed to delete diary: $e');
    }
  }

  @override
  Future<List<DiaryEntryModel>> searchDiaries({
    required String userId,
    required String query,
    int limit = 20,
  }) async {
    try {
      // Note: Firestore doesn't support full-text search natively
      // This implementation fetches all diaries and filters locally
      // For production, consider using a dedicated search service like Algolia
      final collection = _getDiariesCollection(userId);
      final snapshot =
          await collection.orderBy('createdAt', descending: true).get();

      final lowercaseQuery = query.toLowerCase();
      final filtered = snapshot.docs
          .map((doc) => DiaryEntryModel.fromFirestore(doc))
          .where((diary) =>
              diary.title.toLowerCase().contains(lowercaseQuery) ||
              diary.content.toLowerCase().contains(lowercaseQuery))
          .take(limit)
          .toList();

      return filtered;
    } catch (e) {
      throw Exception('Failed to search diaries: $e');
    }
  }

  @override
  Future<List<DiaryEntryModel>> getDiariesByTag({
    required String userId,
    required String tagId,
    int limit = 20,
    String? startAfterDocId,
  }) async {
    try {
      final collection = _getDiariesCollection(userId);
      Query query = collection
          .where('tags', arrayContains: {'id': tagId})
          .orderBy('createdAt', descending: true)
          .limit(limit);

      // Apply pagination if startAfterDocId is provided
      if (startAfterDocId != null) {
        final startAfterDoc = await collection.doc(startAfterDocId).get();
        if (startAfterDoc.exists) {
          query = query.startAfterDocument(startAfterDoc);
        }
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => DiaryEntryModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get diaries by tag: $e');
    }
  }
}
