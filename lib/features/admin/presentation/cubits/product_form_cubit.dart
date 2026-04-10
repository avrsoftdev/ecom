import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../product/domain/entities/product_entity.dart';
import '../../domain/repositories/admin_product_repository.dart';

part 'product_form_state.dart';

class ProductFormCubit extends Cubit<ProductFormState> {
  ProductFormCubit(this._repository, {String? productId})
      : _productId = productId,
        super(ProductFormState.initial(productId: productId));

  final AdminProductRepository _repository;
  final String? _productId;

  Future<void> load() async {
    if (_productId == null) {
      emit(state.copyWith(status: ProductFormStatus.ready));
      return;
    }
    emit(state.copyWith(status: ProductFormStatus.loading));
    final result = await _repository.getById(_productId!);
    result.fold(
      (f) => emit(state.copyWith(status: ProductFormStatus.failure, errorMessage: f.message)),
      (entity) {
        emit(
          state.copyWith(
            status: ProductFormStatus.ready,
            draft: entity,
            imageUrls: entity.imageUrls.isNotEmpty ? entity.imageUrls : [entity.imageUrl],
          ),
        );
      },
    );
  }

  void updateDraft(ProductEntity draft) {
    emit(state.copyWith(draft: draft));
  }

  Future<void> addUploadedUrl(String url) async {
    final urls = [...state.imageUrls.where((e) => e.isNotEmpty)];
    if (!urls.contains(url)) urls.add(url);
    final primary = urls.isNotEmpty ? urls.first : '';
    emit(state.copyWith(imageUrls: urls, draft: _copyDraft(imageUrl: primary, imageUrls: urls)));
  }

  ProductEntity _copyDraft({String? imageUrl, List<String>? imageUrls}) {
    final d = state.draft;
    return ProductEntity(
      id: d.id,
      name: d.name,
      description: d.description,
      price: d.price,
      imageUrl: imageUrl ?? d.imageUrl,
      categoryId: d.categoryId,
      stock: d.stock,
      isAvailable: d.isAvailable,
      createdAt: d.createdAt,
      updatedAt: d.updatedAt,
      discountPercent: d.discountPercent,
      featured: d.featured,
      imageUrls: imageUrls ?? d.imageUrls,
      soldCount: d.soldCount,
    );
  }

  Future<void> save() async {
    emit(state.copyWith(status: ProductFormStatus.saving));
    final now = DateTime.now();
    final d = state.draft;
    final urls = state.imageUrls.where((e) => e.isNotEmpty).toList();
    final primary = urls.isNotEmpty ? urls.first : d.imageUrl;

    final toSave = ProductEntity(
      id: d.id,
      name: d.name,
      description: d.description,
      price: d.price,
      imageUrl: primary,
      categoryId: d.categoryId,
      stock: d.stock,
      isAvailable: d.isAvailable,
      createdAt: _productId == null ? now : d.createdAt,
      updatedAt: now,
      discountPercent: d.discountPercent,
      featured: d.featured,
      imageUrls: urls.length > 1 ? urls : (urls.isEmpty ? [] : urls),
      soldCount: d.soldCount,
    );

    if (_productId == null) {
      final result = await _repository.create(toSave);
      result.fold(
        (f) => emit(state.copyWith(status: ProductFormStatus.failure, errorMessage: f.message)),
        (id) {
          emit(state.copyWith(status: ProductFormStatus.saved, draft: ProductEntity(
            id: id,
            name: toSave.name,
            description: toSave.description,
            price: toSave.price,
            imageUrl: toSave.imageUrl,
            categoryId: toSave.categoryId,
            stock: toSave.stock,
            isAvailable: toSave.isAvailable,
            createdAt: toSave.createdAt,
            updatedAt: toSave.updatedAt,
            discountPercent: toSave.discountPercent,
            featured: toSave.featured,
            imageUrls: toSave.imageUrls,
            soldCount: toSave.soldCount,
          )));
        },
      );
    } else {
      final result = await _repository.update(_productId!, toSave);
      result.fold(
        (f) => emit(state.copyWith(status: ProductFormStatus.failure, errorMessage: f.message)),
        (_) => emit(state.copyWith(status: ProductFormStatus.saved, draft: toSave)),
      );
    }
  }

  Future<void> uploadBytes(List<int> bytes, String fileName) async {
    final pid = _productId ?? state.draft.id;
    final idForPath = pid.isEmpty ? 'draft' : pid;
    final result = await _repository.uploadProductImage(
      productId: idForPath,
      bytes: Uint8List.fromList(bytes),
      fileName: fileName,
    );
    result.fold(
      (f) => emit(state.copyWith(errorMessage: f.message)),
      addUploadedUrl,
    );
  }
}
