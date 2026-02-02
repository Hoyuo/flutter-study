import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

import '../entities/app_settings.dart';
import '../repositories/settings_repository.dart';

class SaveSettingsUseCase implements UseCase<Unit, AppSettings> {
  final SettingsRepository repository;

  SaveSettingsUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(AppSettings params) async {
    return await repository.saveSettings(params);
  }
}
