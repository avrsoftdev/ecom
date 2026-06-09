import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../product/domain/usecases/search_products_usecase.dart';
import 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  final SearchProductsUseCase searchProductsUseCase;

  SearchCubit({required this.searchProductsUseCase}) : super(SearchInitial());

  Future<void> searchProducts(
    String query, {
    double? userLatitude,
    double? userLongitude,
  }) async {
    if (query.isEmpty) {
      emit(SearchInitial());
      return;
    }

    emit(SearchLoading(query));

    final result = await searchProductsUseCase(
      SearchProductsParams(
        query: query,
        userLatitude: userLatitude,
        userLongitude: userLongitude,
      ),
    );

    if (isClosed) return;

    result.fold(
      (failure) => emit(SearchError(failure.message, query)),
      (products) => emit(SearchLoaded(products, query)),
    );
  }

  void clearSearch() {
    emit(SearchInitial());
  }
}
