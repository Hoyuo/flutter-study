import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

import '../entities/app_settings.dart';

abstract class SettingsRepository {
  Future<Either<Failure, AppSettings>> getSettings();
  Future<Either<Failure, Unit>> saveSettings(AppSettings settings);
}
