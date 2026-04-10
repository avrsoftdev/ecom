import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../product/data/models/product_model.dart';
import '../../../product/domain/entities/product_entity.dart';
import '../../domain/repositories/admin_product_repository.dart';
import '../datasources/admin_storage_datasource.dart';
import '../datasources/product_admin_remote_datasource.dart';

class AdminProductRepositoryImpl implements AdminProductRepository {
  AdminProductRepositoryImpl({
    required this.remote,
    required this.storage,
    required this.networkInfo,
  });

  final ProductAdminRemoteDataSource remote;
  final AdminStorageDataSource storage;
  final NetworkInfo networkInfo;

  StockFilterAdmin _mapStock(AdminProductStockFilter f) {
    switch (f) {
      case AdminProductStockFilter.any:
        return StockFilterAdmin.any;
      case AdminProductStockFilter.inStock:
        return StockFilterAdmin.inStock;
      case AdminProductStockFilter.outOfStock:
        return StockFilterAdmin.outOfStock;
      case AdminProductStockFilter.low:
        return StockFilterAdmin.low;
    }
  }

  @override
  Stream<List<ProductEntity>> watchProducts({
    String? categoryId,
    AdminProductStockFilter stock = AdminProductStockFilter.any,
    String searchQuery = '',
    int limit = 50,
  }) {
    return remote
        .watchProducts(
          categoryId: categoryId,
          stock: _mapStock(stock),
          searchPrefix: searchQuery,
          limit: limit,
        )
        .map((list) => list.map((e) => e.toEntity()).toList());
  }

  @override
  Future<Either<Failure, AdminProductPageResult>> fetchPage({
    String? categoryId,
    AdminProductStockFilter stock = AdminProductStockFilter.any,
    String searchQuery = '',
    required int pageSize,
    String? cursorDocumentId,
    String sortField = 'createdAt',
    bool descending = true,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final r = await remote.fetchPage(
        categoryId: categoryId,
        stock: _mapStock(stock),
        searchPrefix: searchQuery,
        pageSize: pageSize,
        cursorDocumentId: cursorDocumentId,
        sortField: sortField,
        descending: descending,
      );
      return Right(
        AdminProductPageResult(
          items: r.items.map((e) => e.toEntity()).toList(),
          lastDocumentId: r.lastId,
        ),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProductEntity>> getById(String id) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final p = await remote.getById(id);
      return Right(p.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> create(ProductEntity product) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final id = await remote.createProduct(ProductModel.fromEntity(product));
      return Right(id);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> update(String id, ProductEntity product) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      await remote.updateProduct(id, ProductModel.fromEntity(product));
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
      await remote.deleteProduct(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadProductImage({
    required String productId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final ext = fileName.contains('.') ? fileName.split('.').last : 'bin';
      final path = 'products/$productId/${DateTime.now().millisecondsSinceEpoch}.$ext';
      final url = await storage.uploadBytes(
        path: path,
        bytes: bytes,
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
      case 'gif':
        return 'image/gif';
      default:
        return null;
    }
  }
}
