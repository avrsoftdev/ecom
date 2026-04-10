import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../product/domain/entities/product_entity.dart';

enum AdminProductStockFilter { any, inStock, outOfStock, low }

class AdminProductPageResult {
  const AdminProductPageResult({required this.items, this.lastDocumentId});

  final List<ProductEntity> items;
  final String? lastDocumentId;
}

abstract class AdminProductRepository {
  Stream<List<ProductEntity>> watchProducts({
    String? categoryId,
    AdminProductStockFilter stock,
    String searchQuery,
    int limit,
  });

  Future<Either<Failure, AdminProductPageResult>> fetchPage({
    String? categoryId,
    AdminProductStockFilter stock,
    String searchQuery,
    required int pageSize,
    String? cursorDocumentId,
    String sortField,
    bool descending,
  });

  Future<Either<Failure, ProductEntity>> getById(String id);

  Future<Either<Failure, String>> create(ProductEntity product);

  Future<Either<Failure, void>> update(String id, ProductEntity product);

  Future<Either<Failure, void>> delete(String id);

  Future<Either<Failure, String>> uploadProductImage({
    required String productId,
    required Uint8List bytes,
    required String fileName,
  });
}
