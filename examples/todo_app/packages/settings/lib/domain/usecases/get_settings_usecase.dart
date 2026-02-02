import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

import '../entities/app_settings.dart';
import '../repositories/settings_repository.dart';

class GetSettingsUseCase implements UseCase<AppSettings, NoParams> {
  final SettingsRepository repository;

  GetSettingsUseCase(this.repository);

  @override
  Future<Either<Failure, AppSettings>> call(NoParams params) async {
    return await repository.getSettings();
  }
}
