import 'package:core/error/failure.dart';
import 'package:core/types/usecase.dart';
import 'package:fpdart/fpdart.dart';

import '../repositories/auth_repository.dart';

/// Use case for signing out the current user
class SignOutUseCase implements UseCase<Unit, NoParams> {
  final AuthRepository _repository;

  const SignOutUseCase(this._repository);

  /// Sign out the current user
  @override
  Future<Either<Failure, Unit>> call(NoParams params) {
    return _repository.signOut();
  }
}
