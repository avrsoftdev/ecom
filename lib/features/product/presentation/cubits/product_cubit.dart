import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/product_entity.dart';
import '../../domain/usecases/get_products_usecase.dart';

part 'product_state.dart';

class ProductCubit extends Cubit<ProductState> {
  final GetProductsUseCase getProductsUseCase;

  ProductCubit({required this.getProductsUseCase}) : super(ProductInitial());

  Future<void> getProducts({
    String? categoryId,
    String? searchQuery,
    int? limit,
    int? offset,
  }) async {
    emit(ProductLoading());

    final params = GetProductsParams(
      categoryId: categoryId,
      searchQuery: searchQuery,
      limit: limit ?? 20,
      offset: offset,
    );

    final result = await getProductsUseCase(params);

    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (products) => emit(ProductLoaded(products)),
    );
  }

  void reset() {
    emit(ProductInitial());
  }
}
