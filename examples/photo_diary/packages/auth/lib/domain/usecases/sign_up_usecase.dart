import 'package:core/error/failure.dart';
import 'package:core/types/usecase.dart';
import 'package:fpdart/fpdart.dart';

import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// 회원가입 파라미터
class SignUpParams {
  final String email;
  final String password;
  final String? displayName;

  const SignUpParams({
    required this.email,
    required this.password,
    this.displayName,
  });
}

/// Use case for signing up with email and password
class SignUpUseCase implements UseCase<User, SignUpParams> {
  final AuthRepository _repository;

  const SignUpUseCase(this._repository);

  /// Sign up with email and password
  @override
  Future<Either<Failure, User>> call(SignUpParams params) {
    return _repository.signUp(
      email: params.email,
      password: params.password,
      displayName: params.displayName,
    );
  }
}
