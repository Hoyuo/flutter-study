import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/core.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../models/models.dart';

/// Implementation of tag repository
class TagRepositoryImpl implements TagRepository {
  final FirebaseFirestore _firestore;
  final CurrentUserService _currentUserService;

  TagRepositoryImpl({
    FirebaseFirestore? firestore,
    required CurrentUserService currentUserService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _currentUserService = currentUserService;

  /// Get reference to user's tags collection
  CollectionReference _getTagsCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('tags');
  }

  @override
  Future<Either<Failure, Tag>> createTag(Tag tag) async {
    try {
      final model = TagModel.fromEntity(tag);
      final collection = _getTagsCollection(tag.userId);

      final docRef = await collection.add(model.toFirestore());
      final doc = await docRef.get();
      final createdModel = TagModel.fromFirestore(doc);

      return Right(createdModel.toEntity());
    } on FirebaseException catch (e) {
      return Left(
        Failure.server(
          message: e.message ?? 'Failed to create tag',
          errorCode: e.code,
        ),
      );
    } on Exception catch (e) {
      return Left(Failure.server(message: e.toString()));
    } catch (e) {
      return Left(Failure.unknown(message: 'Failed to create tag', error: e));
    }
  }

  @override
  Future<Either<Failure, List<Tag>>> getTags() async {
    try {
      final userId = _currentUserService.requireCurrentUserId;
      return getTagsForUser(userId);
    } on StateError catch (e) {
      return Left(Failure.auth(message: e.message));
    } on Exception catch (e) {
      return Left(Failure.server(message: e.toString()));
    } catch (e) {
      return Left(Failure.unknown(message: 'Failed to get tags', error: e));
    }
  }

  /// Get tags for a specific user
  Future<Either<Failure, List<Tag>>> getTagsForUser(String userId) async {
    try {
      final collection = _getTagsCollection(userId);
      final snapshot = await collection.orderBy('name').get();

      final tags = snapshot.docs
          .map((doc) => TagModel.fromFirestore(doc).toEntity())
          .toList();

      return Right(tags);
    } on FirebaseException catch (e) {
      return Left(
        Failure.server(
          message: e.message ?? 'Failed to get tags',
          errorCode: e.code,
        ),
      );
    } on Exception catch (e) {
      return Left(Failure.server(message: e.toString()));
    } catch (e) {
      return Left(Failure.unknown(message: 'Failed to get tags', error: e));
    }
  }

  @override
  Future<Either<Failure, Tag>> updateTag(Tag tag) async {
    try {
      final model = TagModel.fromEntity(tag);
      final docRef = _getTagsCollection(tag.userId).doc(tag.id);

      await docRef.update(model.toFirestore());
      final doc = await docRef.get();

      if (!doc.exists) {
        return Left(
          const Failure.server(message: 'Tag not found after update'),
        );
      }

      final updatedModel = TagModel.fromFirestore(doc);
      return Right(updatedModel.toEntity());
    } on FirebaseException catch (e) {
      return Left(
        Failure.server(
          message: e.message ?? 'Failed to update tag',
          errorCode: e.code,
        ),
      );
    } on Exception catch (e) {
      return Left(Failure.server(message: e.toString()));
    } catch (e) {
      return Left(Failure.unknown(message: 'Failed to update tag', error: e));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteTag(String id) async {
    try {
      final userId = _currentUserService.requireCurrentUserId;
      return deleteTagForUser(userId: userId, tagId: id);
    } on StateError catch (e) {
      return Left(Failure.auth(message: e.message));
    } on Exception catch (e) {
      return Left(Failure.server(message: e.toString()));
    } catch (e) {
      return Left(Failure.unknown(message: 'Failed to delete tag', error: e));
    }
  }

  /// Delete tag for a specific user
  Future<Either<Failure, Unit>> deleteTagForUser({
    required String userId,
    required String tagId,
  }) async {
    try {
      await _getTagsCollection(userId).doc(tagId).delete();
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(
        Failure.server(
          message: e.message ?? 'Failed to delete tag',
          errorCode: e.code,
        ),
      );
    } on Exception catch (e) {
      return Left(Failure.server(message: e.toString()));
    } catch (e) {
      return Left(Failure.unknown(message: 'Failed to delete tag', error: e));
    }
  }
}
