import 'package:auth/data/datasources/auth_remote_datasource.dart';
import 'package:auth/data/models/user_model.dart';
import 'package:auth/domain/entities/user.dart';
import 'package:auth/domain/repositories/auth_repository.dart';
import 'package:core/error/failure.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:fpdart/fpdart.dart';

/// Implementation of AuthRepository using Firebase
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, User>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final firebaseUser = await _remoteDataSource.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userModel = UserModel.fromFirebaseUser(firebaseUser);
      return Right(userModel.toEntity());
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(
        Failure.auth(
          message: _getAuthErrorMessage(e.code),
          errorCode: e.code,
        ),
      );
    } on Object catch (e) {
      return Left(
        Failure.unknown(
          message: 'An unexpected error occurred during sign in',
          error: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, User>> signInWithGoogle() async {
    try {
      final firebaseUser = await _remoteDataSource.signInWithGoogle();

      final userModel = UserModel.fromFirebaseUser(firebaseUser);
      return Right(userModel.toEntity());
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(
        Failure.auth(
          message: _getAuthErrorMessage(e.code),
          errorCode: e.code,
        ),
      );
    } on Object catch (e) {
      return Left(
        Failure.unknown(
          message: 'An unexpected error occurred during Google sign in',
          error: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, User>> signInWithApple() async {
    try {
      final firebaseUser = await _remoteDataSource.signInWithApple();

      final userModel = UserModel.fromFirebaseUser(firebaseUser);
      return Right(userModel.toEntity());
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(
        Failure.auth(
          message: _getAuthErrorMessage(e.code),
          errorCode: e.code,
        ),
      );
    } on Object catch (e) {
      return Left(
        Failure.unknown(
          message: 'An unexpected error occurred during Apple sign in',
          error: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, User>> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final firebaseUser =
          await _remoteDataSource.createUserWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );

      final userModel = UserModel.fromFirebaseUser(firebaseUser);
      return Right(userModel.toEntity());
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(
        Failure.auth(
          message: _getAuthErrorMessage(e.code),
          errorCode: e.code,
        ),
      );
    } on Object catch (e) {
      return Left(
        Failure.unknown(
          message: 'An unexpected error occurred during sign up',
          error: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    try {
      await _remoteDataSource.signOut();
      return const Right(unit);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(
        Failure.auth(
          message: _getAuthErrorMessage(e.code),
          errorCode: e.code,
        ),
      );
    } on Object catch (e) {
      return Left(
        Failure.unknown(
          message: 'An unexpected error occurred during sign out',
          error: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final firebaseUser = await _remoteDataSource.getCurrentUser();

      if (firebaseUser == null) {
        return const Right(null);
      }

      final userModel = UserModel.fromFirebaseUser(firebaseUser);
      return Right(userModel.toEntity());
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(
        Failure.auth(
          message: _getAuthErrorMessage(e.code),
          errorCode: e.code,
        ),
      );
    } on Object catch (e) {
      return Left(
        Failure.unknown(
          message: 'An unexpected error occurred while getting current user',
          error: e,
        ),
      );
    }
  }

  /// Convert Firebase Auth error code to user-friendly message
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'weak-password':
        return 'The password is too weak. Please use a stronger password.';
      case 'invalid-credential':
        return 'The credentials provided are invalid or have expired.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but different sign-in credentials.';
      case 'google-sign-in-cancelled':
        return 'Google Sign In was cancelled.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'An authentication error occurred. Please try again.';
    }
  }
}
