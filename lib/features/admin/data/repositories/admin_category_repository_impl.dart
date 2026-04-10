import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../common/domain/entities/category_entity.dart';
import '../../domain/repositories/admin_category_repository.dart';
import '../datasources/admin_firestore_datasource.dart';
import '../models/category_model.dart';

class AdminCategoryRepositoryImpl implements AdminCategoryRepository {
  AdminCategoryRepositoryImpl({
    required this.remote,
    required this.networkInfo,
  });

  final AdminFirestoreDataSource remote;
  final NetworkInfo networkInfo;

  CategoryModel _model(CategoryEntity e) {
    return CategoryModel(
      id: e.id,
      name: e.name,
      parentId: e.parentId,
      imageUrl: e.imageUrl,
      sortOrder: e.sortOrder,
      createdAt: e.createdAt,
      updatedAt: e.updatedAt,
    );
  }

  @override
  Stream<List<CategoryEntity>> watchCategories() {
    return remote.watchCategories().map((list) => list.map((e) => e as CategoryEntity).toList());
  }

  @override
  Future<Either<Failure, String>> create(CategoryEntity category) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final id = await remote.createCategory(_model(category));
      return Right(id);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> update(String id, CategoryEntity category) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      await remote.updateCategory(id, _model(category));
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
      await remote.deleteCategory(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
