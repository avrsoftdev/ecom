import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/product_entity.dart';
import '../repositories/product_repository.dart';

class SearchProductsUseCase
    implements UseCase<List<ProductEntity>, SearchProductsParams> {
  final ProductRepository repository;

  SearchProductsUseCase(this.repository);

  @override
  Future<Either<Failure, List<ProductEntity>>> call(
    SearchProductsParams params,
  ) async {
    final query = params.query;
    if (query.isEmpty) {
      return const Right([]);
    }

    // Try original query
    final result = await repository.searchProducts(
      query,
      userLatitude: params.userLatitude,
      userLongitude: params.userLongitude,
    );
    
    return result.fold(
      (failure) => Left(failure),
      (products) async {
        if (products.isNotEmpty) {
          return Right(products);
        }

        // If no products found, try capitalized query for case-sensitive Firestore search
        final capitalizedQuery = query[0].toUpperCase() + query.substring(1);
        if (capitalizedQuery != query) {
          final capitalizedResult = await repository.searchProducts(
            capitalizedQuery,
            userLatitude: params.userLatitude,
            userLongitude: params.userLongitude,
          );
          return capitalizedResult;
        }

        return const Right([]);
      },
    );
  }
}

class SearchProductsParams extends Equatable {
  const SearchProductsParams({
    required this.query,
    this.userLatitude,
    this.userLongitude,
  });

  final String query;
  final double? userLatitude;
  final double? userLongitude;

  @override
  List<Object?> get props => [query, userLatitude, userLongitude];
}
