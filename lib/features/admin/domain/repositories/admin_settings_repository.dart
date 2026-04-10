import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../common/domain/entities/store_settings_entity.dart';

abstract class AdminSettingsRepository {
  Future<Either<Failure, StoreSettingsEntity>> getStoreSettings();

  Future<Either<Failure, void>> saveStoreSettings(StoreSettingsEntity settings);

  /// Remote Config `maintenance_mode` (configure in Firebase Console).
  Future<Either<Failure, bool>> fetchRemoteMaintenanceMode();
}
