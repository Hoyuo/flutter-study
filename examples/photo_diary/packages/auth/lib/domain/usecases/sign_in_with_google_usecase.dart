import 'package:core/core.dart';

import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use case for signing in with Google
class SignInWithGoogleUseCase implements UseCase<User, NoParams> {
  final AuthRepository _repository;

  const SignInWithGoogleUseCase(this._repository);

  /// Sign in with Google
  @override
  Future<Either<Failure, User>> call(NoParams params) {
    return _repository.signInWithGoogle();
  }
}
