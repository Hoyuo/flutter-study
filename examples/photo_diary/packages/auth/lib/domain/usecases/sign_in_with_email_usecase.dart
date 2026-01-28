import 'package:core/error/failure.dart';
import 'package:core/types/usecase.dart';
import 'package:fpdart/fpdart.dart';

import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// 이메일/비밀번호 로그인 파라미터
class SignInParams {
  final String email;
  final String password;

  const SignInParams({
    required this.email,
    required this.password,
  });
}

/// Use case for signing in with email and password
class SignInWithEmailUseCase implements UseCase<User, SignInParams> {
  final AuthRepository _repository;

  const SignInWithEmailUseCase(this._repository);

  /// Sign in with email and password
  @override
  Future<Either<Failure, User>> call(SignInParams params) {
    return _repository.signInWithEmail(
      email: params.email,
      password: params.password,
    );
  }
}
