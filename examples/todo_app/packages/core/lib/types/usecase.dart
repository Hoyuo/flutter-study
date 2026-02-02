import 'package:fpdart/fpdart.dart';

import '../error/failure.dart';

/// Base interface for all use cases
///
/// [Type] - The type of the result
/// [Params] - The type of the parameters
abstract class UseCase<Type, Params> {
  /// Execute the use case
  Future<Either<Failure, Type>> call(Params params);
}

/// Empty params class for use cases that don't require parameters
class NoParams {
  const NoParams();
}
