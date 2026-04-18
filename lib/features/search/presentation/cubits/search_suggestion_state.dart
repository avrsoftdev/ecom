import 'package:equatable/equatable.dart';
import '../../../product/domain/entities/product_entity.dart';
import '../../../common/domain/entities/category_entity.dart';

abstract class SearchSuggestionState extends Equatable {
  const SearchSuggestionState();

  @override
  List<Object?> get props => [];
}

class SearchSuggestionInitial extends SearchSuggestionState {}

class SearchSuggestionLoading extends SearchSuggestionState {}

class SearchSuggestionLoaded extends SearchSuggestionState {
  final List<ProductEntity> products;
  final List<CategoryEntity> categories;

  const SearchSuggestionLoaded({
    required this.products,
    required this.categories,
  });

  @override
  List<Object?> get props => [products, categories];
}

class SearchSuggestionError extends SearchSuggestionState {
  final String message;

  const SearchSuggestionError(this.message);

  @override
  List<Object?> get props => [message];
}
