import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/repositories/admin_product_repository.dart';
import '../cubits/product_admin_cubit.dart';

class AdminProductsPage extends StatelessWidget {
  const AdminProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProductAdminCubit>()..loadFirstPage(),
      child: const _AdminProductsView(),
    );
  }
}

class _AdminProductsView extends StatefulWidget {
  const _AdminProductsView();

  @override
  State<_AdminProductsView> createState() => _AdminProductsViewState();
}

class _AdminProductsViewState extends State<_AdminProductsView> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductAdminCubit, ProductAdminState>(
      builder: (context, state) {
        return Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    'Products',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () => context.go('/admin/products/new'),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add product'),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Wrap(
                spacing: 12.w,
                runSpacing: 8.h,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 280.w,
                    child: TextField(
                      controller: _search,
                      decoration: const InputDecoration(
                        labelText: 'Search name',
                        prefixIcon: Icon(Icons.search_rounded),
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (v) => context.read<ProductAdminCubit>().loadFirstPage(
                            search: v,
                            stock: state.stock,
                            categoryId: state.categoryId,
                            sortField: state.sortField,
                            descending: state.sortDescending,
                          ),
                    ),
                  ),
                  DropdownButton<AdminProductStockFilter>(
                    value: state.stock,
                    items: const [
                      DropdownMenuItem(value: AdminProductStockFilter.any, child: Text('Stock: Any')),
                      DropdownMenuItem(value: AdminProductStockFilter.inStock, child: Text('In stock')),
                      DropdownMenuItem(value: AdminProductStockFilter.low, child: Text('Low (<10)')),
                      DropdownMenuItem(value: AdminProductStockFilter.outOfStock, child: Text('Out of stock')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      context.read<ProductAdminCubit>().loadFirstPage(
                            stock: v,
                            search: _search.text,
                            categoryId: state.categoryId,
                          );
                    },
                  ),
                  DropdownButton<String>(
                    value: state.sortField,
                    items: const [
                      DropdownMenuItem(value: 'createdAt', child: Text('Sort: Created')),
                      DropdownMenuItem(value: 'price', child: Text('Sort: Price')),
                      DropdownMenuItem(value: 'name', child: Text('Sort: Name')),
                      DropdownMenuItem(value: 'stock', child: Text('Sort: Stock')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      context.read<ProductAdminCubit>().loadFirstPage(
                            sortField: v,
                            search: _search.text,
                            stock: state.stock,
                            categoryId: state.categoryId,
                            descending: state.sortDescending,
                          );
                    },
                  ),
                  IconButton(
                    tooltip: 'Sort direction',
                    onPressed: () => context.read<ProductAdminCubit>().loadFirstPage(
                          sortField: state.sortField,
                          search: _search.text,
                          stock: state.stock,
                          categoryId: state.categoryId,
                          descending: !state.sortDescending,
                        ),
                    icon: Icon(state.sortDescending ? Icons.arrow_downward : Icons.arrow_upward),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Expanded(
                child: state.status == ProductAdminStatus.loading && state.products.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : Card(
                        child: state.products.isEmpty
                            ? SizedBox(
                                height: 220.h,
                                child: Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.w),
                                    child: Text(
                                      'No products found yet. Add one using the button above or add documents to the Firestore collection "products".',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.bodyLarge,
                                    ),
                                  ),
                                ),
                              )
                            : SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SingleChildScrollView(
                                  child: DataTable(
                                    columns: const [
                                      DataColumn(label: Text('Name')),
                                      DataColumn(label: Text('Category')),
                                      DataColumn(label: Text('Price')),
                                      DataColumn(label: Text('Discount')),
                                      DataColumn(label: Text('Stock')),
                                      DataColumn(label: Text('Featured')),
                                      DataColumn(label: Text('Actions')),
                                    ],
                                    rows: state.products
                                        .map(
                                          (p) => DataRow(
                                            cells: [
                                              DataCell(Text(p.name)),
                                              DataCell(Text(p.categoryId)),
                                              DataCell(Text(formatCurrency(p.effectivePrice))),
                                              DataCell(Text('${p.discountPercent.toStringAsFixed(0)}%')),
                                              DataCell(Text('${p.stock}')),
                                              DataCell(Icon(p.featured ? Icons.star : Icons.star_border)),
                                              DataCell(
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    TextButton(
                                                      onPressed: () => context.go('/admin/products/${p.id}/edit'),
                                                      child: const Text('Edit'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () async {
                                                        final ok = await showDialog<bool>(
                                                          context: context,
                                                          builder: (ctx) => AlertDialog(
                                                            title: const Text('Delete product?'),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () => Navigator.pop(ctx, false),
                                                                child: const Text('Cancel'),
                                                              ),
                                                              FilledButton(
                                                                onPressed: () => Navigator.pop(ctx, true),
                                                                child: const Text('Delete'),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                        if (ok == true && context.mounted) {
                                                          await context.read<ProductAdminCubit>().deleteProduct(p.id);
                                                        }
                                                      },
                                                      child: const Text('Delete'),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              ),
                      ),
              ),
              if (state.hasMore)
                Padding(
                  padding: EdgeInsets.only(top: 12.h),
                  child: Align(
                    alignment: Alignment.center,
                    child: FilledButton(
                      onPressed: state.status == ProductAdminStatus.loadingMore
                          ? null
                          : () => context.read<ProductAdminCubit>().loadMore(),
                      child: state.status == ProductAdminStatus.loadingMore
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Load more'),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
