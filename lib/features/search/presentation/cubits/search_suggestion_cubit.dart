import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import '../../../product/domain/entities/product_entity.dart';
import '../../../product/domain/usecases/search_products_usecase.dart';
import '../../../admin/domain/repositories/admin_category_repository.dart';
import 'search_suggestion_state.dart';

class SearchSuggestionCubit extends Cubit<SearchSuggestionState> {
  final SearchProductsUseCase searchProductsUseCase;
  final AdminCategoryRepository categoryRepository;
  Timer? _debounce;

  SearchSuggestionCubit({
    required this.searchProductsUseCase,
    required this.categoryRepository,
  }) : super(SearchSuggestionInitial());

  void getSuggestions(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    if (query.isEmpty) {
      emit(SearchSuggestionInitial());
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      emit(SearchSuggestionLoading());

      final productResult = await searchProductsUseCase(query);

      List<ProductEntity> products = [];
      productResult.fold(
        (failure) => emit(SearchSuggestionError(failure.message)),
        (p) => products = p,
      );

      // For categories, we fetch all and filter client-side for simplicity
      final categoryStream = categoryRepository.watchCategories();
      final allCategories = await categoryStream.first;
      final filteredCategories = allCategories
          .where((c) => c.name.toLowerCase().contains(query.toLowerCase()))
          .toList();

      emit(SearchSuggestionLoaded(
        products: products,
        categories: filteredCategories,
      ));
    });
  }

  void clearSuggestions() {
    _debounce?.cancel();
    emit(SearchSuggestionInitial());
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
