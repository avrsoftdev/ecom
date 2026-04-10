import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../common/domain/entities/banner_entity.dart';

abstract class AdminBannerRepository {
  Stream<List<BannerEntity>> watchBanners();

  Future<Either<Failure, String>> create(BannerEntity banner);

  Future<Either<Failure, void>> update(String id, BannerEntity banner);

  Future<Either<Failure, void>> delete(String id);

  Future<Either<Failure, String>> uploadBannerImage({
    required String bannerId,
    required List<int> bytes,
    required String fileName,
  });
}
