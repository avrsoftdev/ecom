part of 'product_form_cubit.dart';

enum ProductFormStatus { initial, loading, ready, saving, saved, failure }

class ProductFormState extends Equatable {
  const ProductFormState({
    required this.status,
    required this.draft,
    this.imageUrls = const [],
    this.errorMessage,
  });

  factory ProductFormState.initial({String? productId}) {
    final now = DateTime.now();
    return ProductFormState(
      status: ProductFormStatus.initial,
      draft: ProductEntity(
        id: productId ?? '',
        name: '',
        description: '',
        price: 0,
        imageUrl: '',
        categoryId: '',
        stock: 0,
        isAvailable: true,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  final ProductFormStatus status;
  final ProductEntity draft;
  final List<String> imageUrls;
  final String? errorMessage;

  ProductFormState copyWith({
    ProductFormStatus? status,
    ProductEntity? draft,
    List<String>? imageUrls,
    String? errorMessage,
  }) {
    return ProductFormState(
      status: status ?? this.status,
      draft: draft ?? this.draft,
      imageUrls: imageUrls ?? this.imageUrls,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, draft, imageUrls, errorMessage];
}
