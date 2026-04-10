import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../product/domain/entities/product_entity.dart';
import '../../domain/repositories/admin_product_repository.dart';

part 'product_admin_state.dart';

class ProductAdminCubit extends Cubit<ProductAdminState> {
  ProductAdminCubit(this._repository) : super(const ProductAdminState.initial());

  final AdminProductRepository _repository;

  Future<void> loadFirstPage({
    String? categoryId,
    AdminProductStockFilter stock = AdminProductStockFilter.any,
    String search = '',
    String sortField = 'createdAt',
    bool descending = true,
  }) async {
    emit(
      state.copyWith(
        status: ProductAdminStatus.loading,
        categoryId: categoryId,
        stock: stock,
        searchQuery: search,
        sortField: sortField,
        sortDescending: descending,
        cursorId: null,
      ),
    );

    final result = await _repository.fetchPage(
      categoryId: categoryId,
      stock: stock,
      searchQuery: search,
      pageSize: state.pageSize,
      cursorDocumentId: null,
      sortField: sortField,
      descending: descending,
    );

    result.fold(
      (f) => emit(state.copyWith(status: ProductAdminStatus.failure, errorMessage: f.message)),
      (page) {
        emit(
          state.copyWith(
            status: ProductAdminStatus.success,
            products: page.items,
            cursorId: page.lastDocumentId,
            hasMore: page.items.length >= state.pageSize,
            errorMessage: null,
          ),
        );
      },
    );
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.status == ProductAdminStatus.loadingMore) return;
    emit(state.copyWith(status: ProductAdminStatus.loadingMore));

    final result = await _repository.fetchPage(
      categoryId: state.categoryId,
      stock: state.stock,
      searchQuery: state.searchQuery,
      pageSize: state.pageSize,
      cursorDocumentId: state.cursorId,
      sortField: state.sortField,
      descending: state.sortDescending,
    );

    result.fold(
      (f) => emit(state.copyWith(status: ProductAdminStatus.failure, errorMessage: f.message)),
      (page) {
        emit(
          state.copyWith(
            status: ProductAdminStatus.success,
            products: [...state.products, ...page.items],
            cursorId: page.lastDocumentId,
            hasMore: page.items.length >= state.pageSize,
          ),
        );
      },
    );
  }

  Future<void> deleteProduct(String id) async {
    final result = await _repository.delete(id);
    result.fold(
      (f) => emit(state.copyWith(errorMessage: f.message)),
      (_) {
        emit(state.copyWith(products: state.products.where((p) => p.id != id).toList()));
      },
    );
  }
}
