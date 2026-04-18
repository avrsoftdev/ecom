import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/product_entity.dart';
import '../repositories/product_repository.dart';

class SearchProductsUseCase implements UseCase<List<ProductEntity>, String> {
  final ProductRepository repository;

  SearchProductsUseCase(this.repository);

  @override
  Future<Either<Failure, List<ProductEntity>>> call(String query) async {
    if (query.isEmpty) {
      return const Right([]);
    }

    // Try original query
    final result = await repository.searchProducts(query);
    
    return result.fold(
      (failure) => Left(failure),
      (products) async {
        if (products.isNotEmpty) {
          return Right(products);
        }

        // If no products found, try capitalized query for case-sensitive Firestore search
        final capitalizedQuery = query[0].toUpperCase() + query.substring(1);
        if (capitalizedQuery != query) {
          final capitalizedResult = await repository.searchProducts(capitalizedQuery);
          return capitalizedResult;
        }

        return const Right([]);
      },
    );
  }
}
