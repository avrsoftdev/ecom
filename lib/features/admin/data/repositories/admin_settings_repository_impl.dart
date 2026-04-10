import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../common/domain/entities/store_settings_entity.dart';
import '../../domain/repositories/admin_settings_repository.dart';
import '../datasources/admin_firestore_datasource.dart';
import '../datasources/remote_config_datasource.dart';
import '../models/store_settings_model.dart';

class AdminSettingsRepositoryImpl implements AdminSettingsRepository {
  AdminSettingsRepositoryImpl({
    required this.remote,
    required this.remoteConfig,
    required this.networkInfo,
  });

  final AdminFirestoreDataSource remote;
  final RemoteConfigDataSource remoteConfig;
  final NetworkInfo networkInfo;

  @override
  Future<Either<Failure, StoreSettingsEntity>> getStoreSettings() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final s = await remote.getStoreSettings();
      return Right(s);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveStoreSettings(StoreSettingsEntity settings) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      await remote.saveStoreSettings(
        StoreSettingsModel(
          deliveryCharge: settings.deliveryCharge,
          taxPercent: settings.taxPercent,
          supportEmail: settings.supportEmail,
          supportPhone: settings.supportPhone,
          supportAddress: settings.supportAddress,
          maintenanceMode: settings.maintenanceMode,
        ),
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> fetchRemoteMaintenanceMode() async {
    try {
      await remoteConfig.ensureInitialized();
      return Right(remoteConfig.maintenanceMode);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
