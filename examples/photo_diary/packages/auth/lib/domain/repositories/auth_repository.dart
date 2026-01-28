import 'package:core/error/failure.dart';
import 'package:fpdart/fpdart.dart';

import '../entities/user.dart';

/// Abstract repository for authentication operations
abstract class AuthRepository {
  /// Sign in with email and password
  Future<Either<Failure, User>> signInWithEmail({
    required String email,
    required String password,
  });

  /// Sign in with Google
  Future<Either<Failure, User>> signInWithGoogle();

  /// Sign in with Apple
  Future<Either<Failure, User>> signInWithApple();

  /// Sign up with email and password
  Future<Either<Failure, User>> signUp({
    required String email,
    required String password,
    String? displayName,
  });

  /// Sign out the current user
  Future<Either<Failure, Unit>> signOut();

  /// Get the current authenticated user
  Future<Either<Failure, User?>> getCurrentUser();
}
