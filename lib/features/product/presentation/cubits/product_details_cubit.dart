import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';

part 'product_details_state.dart';

class ProductDetailsCubit extends Cubit<ProductDetailsState> {
  final ProductRepository productRepository;

  ProductDetailsCubit({required this.productRepository}) : super(ProductDetailsInitial());

  Future<void> getProductDetails(String productId) async {
    emit(ProductDetailsLoading());
    
    final result = await productRepository.getProductById(productId);
    
    result.fold(
      (failure) => emit(ProductDetailsError(failure.message)),
      (product) async {
        emit(ProductDetailsLoaded(product: product, relatedProducts: []));
        
        // Load related products based on category
        await _loadRelatedProducts(product.categoryId, productId);
      },
    );
  }

  Future<void> _loadRelatedProducts(String categoryId, String currentProductId) async {
    final result = await productRepository.getProductsByCategory(categoryId);
    
    result.fold(
      (failure) => emit(ProductDetailsError(failure.message)),
      (products) {
        final relatedProducts = products.where((p) => p.id != currentProductId).take(6).toList();
        
        final currentState = state;
        if (currentState is ProductDetailsLoaded) {
          emit(ProductDetailsLoaded(
            product: currentState.product,
            relatedProducts: relatedProducts,
          ));
        }
      },
    );
  }

  void reset() {
    emit(ProductDetailsInitial());
  }
}
