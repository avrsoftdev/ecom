import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/di/injection.dart';
import '../../../common/domain/entities/store_settings_entity.dart';
import '../cubits/settings_cubit.dart';

class SettingsAdminPage extends StatelessWidget {
  const SettingsAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SettingsCubit>()..load(),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatefulWidget {
  const _SettingsView();

  @override
  State<_SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<_SettingsView> {
  final _delivery = TextEditingController();
  final _tax = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();

  @override
  void dispose() {
    _delivery.dispose();
    _tax.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  void _sync(StoreSettingsEntity s) {
    _delivery.text = s.deliveryCharge.toStringAsFixed(2);
    _tax.text = s.taxPercent.toStringAsFixed(2);
    _email.text = s.supportEmail ?? '';
    _phone.text = s.supportPhone ?? '';
    _address.text = s.supportAddress ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SettingsCubit, SettingsState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        final s = state.settings;
        if (s != null && (state.status == SettingsStatus.success || state.status == SettingsStatus.saved)) {
          _sync(s);
        }
        if (state.status == SettingsStatus.failure && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
      },
      builder: (context, state) {
        if (state.status == SettingsStatus.loading && state.settings == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final s = state.settings ??
            const StoreSettingsEntity(
              deliveryCharge: 0,
              taxPercent: 0,
            );

        return SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Settings',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 16.h),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      children: [
                        TextField(
                          controller: _delivery,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Delivery charges',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => _pushDraft(context, s),
                        ),
                        SizedBox(height: 12.h),
                        TextField(
                          controller: _tax,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Tax %',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => _pushDraft(context, s),
                        ),
                        SizedBox(height: 12.h),
                        TextField(
                          controller: _email,
                          decoration: const InputDecoration(
                            labelText: 'Support email',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => _pushDraft(context, s),
                        ),
                        SizedBox(height: 12.h),
                        TextField(
                          controller: _phone,
                          decoration: const InputDecoration(
                            labelText: 'Support phone',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => _pushDraft(context, s),
                        ),
                        SizedBox(height: 12.h),
                        TextField(
                          controller: _address,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Support address',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => _pushDraft(context, s),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Maintenance mode',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Remote Config value (read-only in client): ${state.remoteMaintenance ? 'ON' : 'OFF'}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          'To toggle this, publish the `maintenance_mode` parameter in Firebase Remote Config (or via Admin SDK/REST).',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                FilledButton(
                  onPressed: state.status == SettingsStatus.saving
                      ? null
                      : () {
                          _pushDraft(context, s);
                          context.read<SettingsCubit>().save();
                        },
                  child: state.status == SettingsStatus.saving
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _pushDraft(BuildContext context, StoreSettingsEntity current) {
    final delivery = double.tryParse(_delivery.text) ?? current.deliveryCharge;
    final tax = double.tryParse(_tax.text) ?? current.taxPercent;
    final next = StoreSettingsEntity(
      deliveryCharge: delivery,
      taxPercent: tax,
      supportEmail: _email.text.trim().isEmpty ? null : _email.text.trim(),
      supportPhone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      supportAddress: _address.text.trim().isEmpty ? null : _address.text.trim(),
      maintenanceMode: current.maintenanceMode,
    );
    context.read<SettingsCubit>().updateDraft(next);
  }
}

