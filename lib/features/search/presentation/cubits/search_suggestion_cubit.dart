import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import '../../../../core/services/vendor_delivery_service.dart';
import '../../../common/domain/entities/category_entity.dart';
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

  void getSuggestions(
    String query, {
    double? userLatitude,
    double? userLongitude,
  }) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    if (query.isEmpty) {
      emit(SearchSuggestionInitial());
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      emit(SearchSuggestionLoading());

      final productResult = await searchProductsUseCase(
        SearchProductsParams(
          query: query,
          userLatitude: userLatitude,
          userLongitude: userLongitude,
        ),
      );

      if (isClosed) return;

      List<ProductEntity> products = [];
      productResult.fold(
        (failure) => emit(SearchSuggestionError(failure.message)),
        (p) => products = p,
      );

      if (isClosed) return;

      // For categories, we fetch all and filter client-side
      final categoryStream = categoryRepository.watchCategories();
      final allCategories = await categoryStream.first;

      if (isClosed) return;

      // Filter by name
      final matchedCategories = allCategories
          .where((c) => c.name.toLowerCase().contains(query.toLowerCase()))
          .toList();

      // Filter by vendor serviceability if location is available
      List<CategoryEntity> filteredCategories = matchedCategories;
      if (userLatitude != null && userLongitude != null) {
        final vendorIds = matchedCategories
            .map((c) => c.vendorId)
            .where((id) => id != null && id.trim().isNotEmpty)
            .cast<String>()
            .toSet();

        if (vendorIds.isNotEmpty) {
          final vendorService = VendorDeliveryService(
            firestore: FirebaseFirestore.instance,
          );
          final vendorMap = await vendorService.loadVendorMetadata(vendorIds);

          if (isClosed) return;

          filteredCategories = matchedCategories.where((c) {
            final vendorId = c.vendorId;
            if (vendorId == null || vendorId.trim().isEmpty) {
              return true;
            }

            final vendor = vendorMap[vendorId];
            if (vendor == null || vendor.isBlocked) return false;
            if (vendor.latitude == null || vendor.longitude == null) {
              return false;
            }

            final distanceKm = VendorDeliveryService.haversineDistanceKm(
              userLatitude,
              userLongitude,
              vendor.latitude!,
              vendor.longitude!,
            );

            return distanceKm <= vendor.deliveryRadiusKm;
          }).toList();
        }
      }

      if (isClosed) return;

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
