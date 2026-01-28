import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

import '../entities/entities.dart';
import '../repositories/repositories.dart';

/// Use case for updating app settings
class UpdateSettingsUseCase
    implements UseCase<AppSettings, UpdateSettingsParams> {
  final SettingsRepository _repository;

  const UpdateSettingsUseCase(this._repository);

  @override
  Future<Either<Failure, AppSettings>> call(UpdateSettingsParams params) {
    return _repository.updateSettings(params.settings);
  }
}

/// Parameters for updating settings
class UpdateSettingsParams {
  final AppSettings settings;

  const UpdateSettingsParams({
    required this.settings,
  });
}
