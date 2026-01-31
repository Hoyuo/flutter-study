import 'package:core/core.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../datasources/datasources.dart';
import '../models/models.dart';

/// Implementation of diary repository
class DiaryRepositoryImpl implements DiaryRepository {
  final DiaryRemoteDataSource _remoteDataSource;
  final DiaryLocalDataSource? _localDataSource;
  final ImageStorageDataSource _imageStorageDataSource;
  final CurrentUserService _currentUserService;

  DiaryRepositoryImpl({
    required DiaryRemoteDataSource remoteDataSource,
    DiaryLocalDataSource? localDataSource,
    required ImageStorageDataSource imageStorageDataSource,
    required CurrentUserService currentUserService,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _imageStorageDataSource = imageStorageDataSource,
        _currentUserService = currentUserService;

  @override
  Future<Either<Failure, DiaryEntry>> createDiary(DiaryEntry entry) async {
    try {
      // Convert entity to model
      final model = DiaryEntryModel.fromEntity(entry);

      // Create diary in remote data source
      final createdModel = await _remoteDataSource.createDiary(model);

      // Cache locally if local data source is available
      if (_localDataSource != null) {
        try {
          await _localDataSource.cacheDiary(createdModel);
        } catch (e, stackTrace) {
          // Log cache error but don't fail the operation
          AppLogger.w('Failed to cache diary after creation', e, stackTrace);
        }
      }

      // Convert back to entity and return
      return Right(createdModel.toEntity());
    } on Exception catch (e) {
      return Left(Failure.server(message: e.toString()));
    } catch (e) {
      return Left(Failure.unknown(message: 'Failed to create diary', error: e));
    }
  }

  @override
  Future<Either<Failure, List<DiaryEntry>>> getDiaries({
    int limit = 20,
    String? lastEntryId,
  }) async {
    try {
      final userId = _currentUserService.requireCurrentUserId;
      return getDiariesForUser(
        userId: userId,
        limit: limit,
        lastEntryId: lastEntryId,
      );
    } on StateError catch (e) {
      return Left(Failure.auth(message: e.message));
    } on Exception catch (e) {
      return Left(Failure.server(message: e.toString()));
    } catch (e) {
      return Left(Failure.unknown(message: 'Failed to get diaries', error: e));
    }
  }

  /// Get diaries for a specific user
  Future<Either<Failure, List<DiaryEntry>>> getDiariesForUser({
    required String userId,
    int limit = 20,
    String? lastEntryId,
  }) async {
    try {
      // Try to get from remote first
      final models = await _remoteDataSource.getDiaries(
        userId: userId,
        limit: limit,
        startAfterDocId: lastEntryId,
      );

      // Cache the results if local data source is available
      if (_localDataSource != null && models.isNotEmpty) {
        try {
          await _localDataSource.cacheDiaries(models);
        } catch (e, stackTrace) {
          // Log cache error but don't fail the operation
          AppLogger.w('Failed to cache diaries list', e, stackTrace);
        }
      }

      // Convert models to entities
      final entries = models.map((m) => m.toEntity()).toList();
      return Right(entries);
    } on Exception catch (e) {
      // Try to get from cache if remote fails
      if (_localDataSource != null) {
        try {
          final cachedModels = await _localDataSource.getCachedDiaries(
            userId: userId,
            limit: limit,
          );
          if (cachedModels.isNotEmpty) {
            final entries = cachedModels.map((m) => m.toEntity()).toList();
            return Right(entries);
          }
        } catch (cacheError, stackTrace) {
          // Cache also failed, return original error
          AppLogger.w('Failed to retrieve cached diaries as fallback', cacheError, stackTrace);
        }
      }
      return Left(Failure.server(message: e.toString()));
    } catch (e) {
      return Left(Failure.unknown(message: 'Failed to get diaries', error: e));
    }
  }

  @override
  Future<Either<Failure, DiaryEntry>> getDiaryById(String id) async {
    try {
      final userId = _currentUserService.requireCurrentUserId;
      return getDiaryByIdForUser(userId: userId, diaryId: id);
    } on StateError catch (e) {
      return Left(Failure.auth(message: e.message));
    } on Exception catch (e) {
      return Left(Failure.server(message: e.toString()));
    } catch (e) {
      return Left(Failure.unknown(message: 'Failed to get diary', error: e));
    }
  }

  /// Get diary by ID for a specific user
  Future<Either<Failure, DiaryEntry>> getDiaryByIdForUser({
    required String userId,
    required String diaryId,
  }) async {
    try {
      // Try to get from remote first
      final model = await _remoteDataSource.getDiaryById(
        userId: userId,
        diaryId: diaryId,
      );

      // Cache the result if local data source is available
      if (_localDataSource != null) {
        try {
          await _localDataSource.cacheDiary(model);
        } catch (e, stackTrace) {
          // Log cache error but don't fail the operation
          AppLogger.w('Failed to cache diary by ID', e, stackTrace);
        }
      }

      return Right(model.toEntity());
    } on Exception catch (e) {
      // Try to get from cache if remote fails
      if (_localDataSource != null) {
        try {
          final cachedModel =
              await _localDataSource.getCachedDiaryById(diaryId);
          if (cachedModel != null) {
            return Right(cachedModel.toEntity());
          }
        } catch (cacheError, stackTrace) {
          // Cache also failed, return original error
          AppLogger.w('Failed to retrieve cached diary by ID as fallback', cacheError, stackTrace);
        }
      }
      return Left(Failure.server(message: e.toString()));
    } catch (e) {
      return Left(Failure.unknown(message: 'Failed to get diary', error: e));
    }
  }

  @override
  Future<Either<Failure, DiaryEntry>> updateDiary(DiaryEntry entry) async {
    try {
      // Convert entity to model
      final model = DiaryEntryModel.fromEntity(entry);

      // Update in remote data source
      final updatedModel = await _remoteDataSource.updateDiary(model);

      // Update cache if local data source is available
      if (_localDataSource != null) {
        try {
          await _localDataSource.updateCachedDiary(updatedModel);
        } catch (e, stackTrace) {
          // Log cache error but don't fail the operation
          AppLogger.w('Failed to update cached diary', e, stackTrace);
        }
      }

      return Right(updatedModel.toEntity());
    } on Exception catch (e) {
      return Left(Failure.server(message: e.toString()));
    } catch (e) {
      return Left(Failure.unknown(message: 'Failed to update diary', error: e));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteDiary(String id) async {
    try {
      final userId = _currentUserService.requireCurrentUserId;
      return deleteDiaryForUser(userId: userId, diaryId: id);
    } on StateError catch (e) {
      return Left(Failure.auth(message: e.message));
    } on Exception catch (e) {
      return Left(Failure.server(message: e.toString()));
    } catch (e) {
      return Left(Failure.unknown(message: 'Failed to delete diary', error: e));
    }
  }

  /// Delete diary for a specific user
  Future<Either<Failure, Unit>> deleteDiaryForUser({
    required String userId,
    required String diaryId,
  }) async {
    try {
      // Delete images first
      try {
        await _imageStorageDataSource.deleteAllImagesForDiary(
          userId: userId,
          diaryId: diaryId,
        );
      } catch (e, stackTrace) {
        // Log error but continue with diary deletion
        AppLogger.w('Failed to delete images for diary', e, stackTrace);
      }

      // Delete from remote data source
      await _remoteDataSource.deleteDiary(
        userId: userId,
        diaryId: diaryId,
      );

      // Delete from cache if local data source is available
      if (_localDataSource != null) {
        try {
          await _localDataSource.deleteCachedDiary(diaryId);
        } catch (e, stackTrace) {
          // Log cache error but don't fail the operation
          AppLogger.w('Failed to delete cached diary', e, stackTrace);
        }
      }

      return const Right(unit);
    } on Exception catch (e) {
      return Left(Failure.server(message: e.toString()));
    } catch (e) {
      return Left(Failure.unknown(message: 'Failed to delete diary', error: e));
    }
  }

  @override
  Future<Either<Failure, List<DiaryEntry>>> searchDiaries({
    required String query,
    int limit = 20,
  }) async {
    try {
      final userId = _currentUserService.requireCurrentUserId;
      return searchDiariesForUser(userId: userId, query: query, limit: limit);
    } on StateError catch (e) {
      return Left(Failure.auth(message: e.message));
    } on Exception catch (e) {
      return Left(Failure.server(message: e.toString()));
    } catch (e) {
      return Left(
          Failure.unknown(message: 'Failed to search diaries', error: e));
    }
  }

  /// Search diaries for a specific user
  Future<Either<Failure, List<DiaryEntry>>> searchDiariesForUser({
    required String userId,
    required String query,
    int limit = 20,
  }) async {
    try {
      final models = await _remoteDataSource.searchDiaries(
        userId: userId,
        query: query,
        limit: limit,
      );

      final entries = models.map((m) => m.toEntity()).toList();
      return Right(entries);
    } on Exception catch (e) {
      return Left(Failure.server(message: e.toString()));
    } catch (e) {
      return Left(
          Failure.unknown(message: 'Failed to search diaries', error: e));
    }
  }

  @override
  Future<Either<Failure, List<DiaryEntry>>> getDiariesByTag({
    required String tagId,
    int limit = 20,
    String? lastEntryId,
  }) async {
    try {
      final userId = _currentUserService.requireCurrentUserId;
      return getDiariesByTagForUser(
        userId: userId,
        tagId: tagId,
        limit: limit,
        lastEntryId: lastEntryId,
      );
    } on StateError catch (e) {
      return Left(Failure.auth(message: e.message));
    } on Exception catch (e) {
      return Left(Failure.server(message: e.toString()));
    } catch (e) {
      return Left(
        Failure.unknown(message: 'Failed to get diaries by tag', error: e),
      );
    }
  }

  /// Get diaries by tag for a specific user
  Future<Either<Failure, List<DiaryEntry>>> getDiariesByTagForUser({
    required String userId,
    required String tagId,
    int limit = 20,
    String? lastEntryId,
  }) async {
    try {
      final models = await _remoteDataSource.getDiariesByTag(
        userId: userId,
        tagId: tagId,
        limit: limit,
        startAfterDocId: lastEntryId,
      );

      final entries = models.map((m) => m.toEntity()).toList();
      return Right(entries);
    } on Exception catch (e) {
      return Left(Failure.server(message: e.toString()));
    } catch (e) {
      return Left(
        Failure.unknown(message: 'Failed to get diaries by tag', error: e),
      );
    }
  }
}
