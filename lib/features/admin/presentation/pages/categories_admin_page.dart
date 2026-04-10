import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/di/injection.dart';
import '../../../common/domain/entities/category_entity.dart';
import '../../domain/repositories/admin_category_repository.dart';

class CategoriesAdminPage extends StatelessWidget {
  const CategoriesAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = getIt<AdminCategoryRepository>();

    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Categories',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _showEditDialog(context, repo, null),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add category'),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: StreamBuilder<List<CategoryEntity>>(
              stream: repo.watchCategories(),
              builder: (context, snap) {
                if (snap.hasError) return Center(child: Text('${snap.error}'));
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final list = snap.data!;
                if (list.isEmpty) {
                  return const Center(child: Text('No categories — add one to get started.'));
                }
                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final c = list[i];
                    return ListTile(
                      title: Text(c.name),
                      subtitle: Text(
                        c.parentId == null ? 'Top level' : 'Sub-category (parent: ${c.parentId})',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_rounded),
                            onPressed: () => _showEditDialog(context, repo, c),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded),
                            onPressed: () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete category?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                                  ],
                                ),
                              );
                              if (ok == true) await repo.delete(c.id);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    AdminCategoryRepository repo,
    CategoryEntity? existing,
  ) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final parentCtrl = TextEditingController(text: existing?.parentId ?? '');
    final imageCtrl = TextEditingController(text: existing?.imageUrl ?? '');
    final sortCtrl = TextEditingController(text: '${existing?.sortOrder ?? 0}');

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(existing == null ? 'New category' : 'Edit category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
                TextField(
                  controller: parentCtrl,
                  decoration: const InputDecoration(labelText: 'Parent category ID (optional)'),
                ),
                TextField(
                  controller: imageCtrl,
                  decoration: const InputDecoration(labelText: 'Image URL'),
                ),
                TextField(
                  controller: sortCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Sort order'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final now = DateTime.now();
                final sort = int.tryParse(sortCtrl.text) ?? 0;
                final parent = parentCtrl.text.trim().isEmpty ? null : parentCtrl.text.trim();
                final img = imageCtrl.text.trim().isEmpty ? null : imageCtrl.text.trim();
                if (existing == null) {
                  await repo.create(
                    CategoryEntity(
                      id: '',
                      name: nameCtrl.text.trim(),
                      parentId: parent,
                      imageUrl: img,
                      sortOrder: sort,
                      createdAt: now,
                    ),
                  );
                } else {
                  await repo.update(
                    existing.id,
                    CategoryEntity(
                      id: existing.id,
                      name: nameCtrl.text.trim(),
                      parentId: parent,
                      imageUrl: img,
                      sortOrder: sort,
                      createdAt: existing.createdAt,
                      updatedAt: now,
                    ),
                  );
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
