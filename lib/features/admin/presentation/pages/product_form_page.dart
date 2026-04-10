import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../common/domain/entities/category_entity.dart';
import '../../../product/domain/entities/product_entity.dart';
import '../../domain/repositories/admin_category_repository.dart';
import '../cubits/product_form_cubit.dart';

class ProductFormPage extends StatelessWidget {
  const ProductFormPage({super.key, this.productId});

  /// `null` = create new product.
  final String? productId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProductFormCubit(getIt(), productId: productId)..load(),
      child: _ProductFormView(isEditing: productId != null),
    );
  }
}

class _ProductFormView extends StatefulWidget {
  const _ProductFormView({required this.isEditing});

  final bool isEditing;

  @override
  State<_ProductFormView> createState() => _ProductFormViewState();
}

class _ProductFormViewState extends State<_ProductFormView> {
  late final _name = TextEditingController();
  late final _desc = TextEditingController();
  late final _price = TextEditingController();
  late final _discount = TextEditingController();
  late final _stock = TextEditingController();
  late final _category = TextEditingController();

  String? _categoryId;

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _price.dispose();
    _discount.dispose();
    _stock.dispose();
    _category.dispose();
    super.dispose();
  }

  void _sync(ProductEntity d) {
    _name.text = d.name;
    _desc.text = d.description;
    _price.text = d.price.toStringAsFixed(2);
    _discount.text = d.discountPercent.toStringAsFixed(0);
    _stock.text = d.stock.toString();
    _categoryId = d.categoryId;
    _category.text = d.categoryId;
  }

  @override
  Widget build(BuildContext context) {
    final categories = getIt<AdminCategoryRepository>().watchCategories();

    return BlocConsumer<ProductFormCubit, ProductFormState>(
      listener: (context, state) {
        if (state.status == ProductFormStatus.ready || state.status == ProductFormStatus.saved) {
          _sync(state.draft);
        }
        if (state.status == ProductFormStatus.saved) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
          if (!widget.isEditing && state.draft.id.isNotEmpty) {
            context.go('/admin/products/${state.draft.id}/edit');
          }
        }
      },
      builder: (context, state) {
        if (state.status == ProductFormStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.isEditing ? 'Edit product' : 'New product',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 20.h),
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => _pushDraft(context),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: _desc,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => _pushDraft(context),
                ),
                SizedBox(height: 12.h),
                StreamBuilder<List<CategoryEntity>>(
                  stream: categories,
                  builder: (context, snap) {
                    final list = snap.data ?? [];
                    return DropdownButtonFormField<String>(
                      value: _categoryId != null && _categoryId!.isNotEmpty ? _categoryId : null,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: list
                          .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                          .toList(),
                      onChanged: (v) {
                        setState(() => _categoryId = v);
                        _pushDraft(context);
                      },
                    );
                  },
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _price,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Price',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => _pushDraft(context),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: TextField(
                        controller: _discount,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Discount %',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => _pushDraft(context),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: TextField(
                        controller: _stock,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Stock',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => _pushDraft(context),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                SwitchListTile(
                  title: const Text('Featured'),
                  value: state.draft.featured,
                  onChanged: (v) {
                    context.read<ProductFormCubit>().updateDraft(
                          _entityFromFields(context, featured: v),
                        );
                  },
                ),
                SwitchListTile(
                  title: const Text('Available'),
                  value: state.draft.isAvailable,
                  onChanged: (v) {
                    context.read<ProductFormCubit>().updateDraft(
                          _entityFromFields(context, isAvailable: v),
                        );
                  },
                ),
                SizedBox(height: 16.h),
                Text('Images', style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final url in state.imageUrls.where((e) => e.isNotEmpty))
                      Chip(label: Text(url.length > 40 ? '${url.substring(0, 40)}…' : url)),
                    OutlinedButton.icon(
                      onPressed: state.status == ProductFormStatus.saving
                          ? null
                          : () async {
                              final cubit = context.read<ProductFormCubit>();
                              final r = await FilePicker.platform.pickFiles(
                                type: FileType.image,
                                withData: kIsWeb,
                              );
                              if (r == null || r.files.isEmpty) return;
                              final f = r.files.first;
                              final bytes = f.bytes;
                              if (bytes == null) return;
                              await cubit.uploadBytes(bytes, f.name);
                            },
                      icon: const Icon(Icons.upload_rounded),
                      label: const Text('Upload image'),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
                FilledButton(
                  onPressed: state.status == ProductFormStatus.saving
                      ? null
                      : () {
                          context.read<ProductFormCubit>().updateDraft(_entityFromFields(context));
                          context.read<ProductFormCubit>().save();
                        },
                  child: state.status == ProductFormStatus.saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _pushDraft(BuildContext context) {
    context.read<ProductFormCubit>().updateDraft(_entityFromFields(context));
  }

  ProductEntity _entityFromFields(
    BuildContext context, {
    bool? featured,
    bool? isAvailable,
  }) {
    final s = context.read<ProductFormCubit>().state;
    final c = s.draft;
    final urls = s.imageUrls.where((e) => e.isNotEmpty).toList();
    final price = double.tryParse(_price.text) ?? c.price;
    final disc = double.tryParse(_discount.text) ?? c.discountPercent;
    final stock = int.tryParse(_stock.text) ?? c.stock;
    final primary = urls.isNotEmpty ? urls.first : c.imageUrl;
    return ProductEntity(
      id: c.id,
      name: _name.text,
      description: _desc.text,
      price: price,
      imageUrl: primary,
      categoryId: _categoryId ?? c.categoryId,
      stock: stock,
      isAvailable: isAvailable ?? c.isAvailable,
      createdAt: c.createdAt,
      updatedAt: c.updatedAt,
      discountPercent: disc,
      featured: featured ?? c.featured,
      imageUrls: urls,
      soldCount: c.soldCount,
    );
  }
}
