import 'package:equatable/equatable.dart';
import '../../../product/domain/entities/product_entity.dart';

abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => [];
}

class SearchInitial extends SearchState {}

class SearchLoading extends SearchState {
  final String query;

  const SearchLoading(this.query);

  @override
  List<Object?> get props => [query];
}

class SearchLoaded extends SearchState {
  final List<ProductEntity> products;
  final String query;

  const SearchLoaded(this.products, this.query);

  @override
  List<Object?> get props => [products, query];
}

class SearchError extends SearchState {
  final String message;
  final String query;

  const SearchError(this.message, this.query);

  @override
  List<Object?> get props => [message, query];
}
