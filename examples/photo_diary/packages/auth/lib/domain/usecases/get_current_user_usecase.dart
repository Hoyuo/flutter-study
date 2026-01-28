import 'package:core/error/failure.dart';
import 'package:core/types/usecase.dart';
import 'package:fpdart/fpdart.dart';

import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use case for getting the current authenticated user
class GetCurrentUserUseCase implements UseCase<User?, NoParams> {
  final AuthRepository _repository;

  const GetCurrentUserUseCase(this._repository);

  /// Get the current authenticated user
  @override
  Future<Either<Failure, User?>> call(NoParams params) {
    return _repository.getCurrentUser();
  }
}
