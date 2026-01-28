import 'package:core/error/failure.dart';
import 'package:fpdart/fpdart.dart';

import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use case for signing in with Google
class SignInWithGoogleUseCase {
  final AuthRepository _repository;

  const SignInWithGoogleUseCase(this._repository);

  /// Sign in with Google
  Future<Either<Failure, User>> call() {
    return _repository.signInWithGoogle();
  }
}
