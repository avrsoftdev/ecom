import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/di/injection.dart';
import '../../../common/domain/entities/banner_entity.dart';
import '../../domain/repositories/admin_banner_repository.dart';

class BannersAdminPage extends StatelessWidget {
  const BannersAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = getIt<AdminBannerRepository>();

    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Banners',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _editBanner(context, repo, null),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add banner'),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: StreamBuilder<List<BannerEntity>>(
              stream: repo.watchBanners(),
              builder: (context, snap) {
                if (snap.hasError) return Center(child: Text('${snap.error}'));
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final list = snap.data!;
                if (list.isEmpty) {
                  return const Center(child: Text('No banners'));
                }
                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final b = list[i];
                    return ListTile(
                      leading: Icon(b.isActive ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                      title: Text(b.title),
                      subtitle: Text('${b.linkType.name} ${b.linkId ?? ''}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit_rounded), onPressed: () => _editBanner(context, repo, b)),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded),
                            onPressed: () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete banner?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                                  ],
                                ),
                              );
                              if (ok == true) await repo.delete(b.id);
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

  Future<void> _editBanner(BuildContext context, AdminBannerRepository repo, BannerEntity? existing) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final linkIdCtrl = TextEditingController(text: existing?.linkId ?? '');
    var linkType = existing?.linkType ?? BannerLinkType.none;
    var active = existing?.isActive ?? true;
    var sort = existing?.sortOrder ?? 0;
    String? imageUrl = existing?.imageUrl;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: Text(existing == null ? 'New banner' : 'Edit banner'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
                    DropdownButtonFormField<BannerLinkType>(
                      value: linkType,
                      decoration: const InputDecoration(labelText: 'Link type'),
                      items: BannerLinkType.values
                          .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                          .toList(),
                      onChanged: (v) => setLocal(() => linkType = v ?? BannerLinkType.none),
                    ),
                    TextField(controller: linkIdCtrl, decoration: const InputDecoration(labelText: 'Link ID')),
                    SwitchListTile(
                      title: const Text('Active'),
                      value: active,
                      onChanged: (v) => setLocal(() => active = v),
                    ),
                    TextFormField(
                      initialValue: '$sort',
                      decoration: const InputDecoration(labelText: 'Sort order'),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => sort = int.tryParse(v) ?? 0,
                    ),
                    if (imageUrl != null) Text('Image: $imageUrl', maxLines: 2, overflow: TextOverflow.ellipsis),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final r = await FilePicker.platform.pickFiles(type: FileType.image, withData: kIsWeb);
                        if (r == null || r.files.isEmpty) return;
                        final f = r.files.first;
                        final bytes = f.bytes;
                        if (bytes == null) return;
                        final bid = existing?.id ?? 'new';
                        final res = await repo.uploadBannerImage(bannerId: bid, bytes: bytes, fileName: f.name);
                        res.fold((l) => null, (u) => setLocal(() => imageUrl = u));
                      },
                      icon: const Icon(Icons.upload_rounded),
                      label: const Text('Upload image'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                FilledButton(
                  onPressed: () async {
                    final now = DateTime.now();
                    final banner = BannerEntity(
                      id: existing?.id ?? '',
                      title: titleCtrl.text.trim(),
                      imageUrl: imageUrl ?? '',
                      linkType: linkType,
                      linkId: linkIdCtrl.text.trim().isEmpty ? null : linkIdCtrl.text.trim(),
                      isActive: active,
                      sortOrder: sort,
                      createdAt: existing?.createdAt ?? now,
                      updatedAt: now,
                    );
                    if (existing == null) {
                      await repo.create(banner);
                    } else {
                      await repo.update(existing.id, banner);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
