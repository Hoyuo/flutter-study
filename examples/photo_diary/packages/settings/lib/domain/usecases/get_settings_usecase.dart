import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

import '../entities/entities.dart';
import '../repositories/repositories.dart';

/// Use case for getting app settings
class GetSettingsUseCase implements UseCase<AppSettings, NoParams> {
  final SettingsRepository _repository;

  const GetSettingsUseCase(this._repository);

  @override
  Future<Either<Failure, AppSettings>> call(NoParams params) {
    return _repository.getSettings();
  }
}
