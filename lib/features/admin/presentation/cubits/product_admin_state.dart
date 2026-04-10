part of 'product_admin_cubit.dart';

enum ProductAdminStatus { initial, loading, loadingMore, success, failure }

class ProductAdminState extends Equatable {
  const ProductAdminState({
    required this.status,
    this.products = const [],
    this.categoryId,
    this.stock = AdminProductStockFilter.any,
    this.searchQuery = '',
    this.sortField = 'createdAt',
    this.sortDescending = true,
    this.cursorId,
    this.hasMore = true,
    this.pageSize = 20,
    this.errorMessage,
  });

  const ProductAdminState.initial() : this(status: ProductAdminStatus.initial);

  final ProductAdminStatus status;
  final List<ProductEntity> products;
  final String? categoryId;
  final AdminProductStockFilter stock;
  final String searchQuery;
  final String sortField;
  final bool sortDescending;
  final String? cursorId;
  final bool hasMore;
  final int pageSize;
  final String? errorMessage;

  ProductAdminState copyWith({
    ProductAdminStatus? status,
    List<ProductEntity>? products,
    String? categoryId,
    AdminProductStockFilter? stock,
    String? searchQuery,
    String? sortField,
    bool? sortDescending,
    String? cursorId,
    bool? hasMore,
    int? pageSize,
    String? errorMessage,
  }) {
    return ProductAdminState(
      status: status ?? this.status,
      products: products ?? this.products,
      categoryId: categoryId ?? this.categoryId,
      stock: stock ?? this.stock,
      searchQuery: searchQuery ?? this.searchQuery,
      sortField: sortField ?? this.sortField,
      sortDescending: sortDescending ?? this.sortDescending,
      cursorId: cursorId ?? this.cursorId,
      hasMore: hasMore ?? this.hasMore,
      pageSize: pageSize ?? this.pageSize,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        products,
        categoryId,
        stock,
        searchQuery,
        sortField,
        sortDescending,
        cursorId,
        hasMore,
        pageSize,
        errorMessage,
      ];
}
