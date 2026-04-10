import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../common/domain/entities/banner_entity.dart';
import '../../domain/repositories/admin_banner_repository.dart';
import '../datasources/admin_firestore_datasource.dart';
import '../datasources/admin_storage_datasource.dart';
import '../models/banner_model.dart';

class AdminBannerRepositoryImpl implements AdminBannerRepository {
  AdminBannerRepositoryImpl({
    required this.remote,
    required this.storage,
    required this.networkInfo,
  });

  final AdminFirestoreDataSource remote;
  final AdminStorageDataSource storage;
  final NetworkInfo networkInfo;

  BannerModel _model(BannerEntity e) {
    return BannerModel(
      id: e.id,
      title: e.title,
      imageUrl: e.imageUrl,
      linkType: e.linkType,
      linkId: e.linkId,
      isActive: e.isActive,
      sortOrder: e.sortOrder,
      createdAt: e.createdAt,
      updatedAt: e.updatedAt,
    );
  }

  @override
  Stream<List<BannerEntity>> watchBanners() {
    return remote.watchBanners().map((list) => list.map((e) => e as BannerEntity).toList());
  }

  @override
  Future<Either<Failure, String>> create(BannerEntity banner) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final id = await remote.createBanner(_model(banner));
      return Right(id);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> update(String id, BannerEntity banner) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      await remote.updateBanner(id, _model(banner));
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> delete(String id) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      await remote.deleteBanner(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadBannerImage({
    required String bannerId,
    required List<int> bytes,
    required String fileName,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final ext = fileName.contains('.') ? fileName.split('.').last : 'bin';
      final path = 'banners/$bannerId/${DateTime.now().millisecondsSinceEpoch}.$ext';
      final url = await storage.uploadBytes(
        path: path,
        bytes: Uint8List.fromList(bytes),
        contentType: _guessContentType(ext),
      );
      return Right(url);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  String? _guessContentType(String ext) {
    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return null;
    }
  }
}
