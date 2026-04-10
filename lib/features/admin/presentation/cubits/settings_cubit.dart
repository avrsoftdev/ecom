import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../common/domain/entities/store_settings_entity.dart';
import '../../domain/repositories/admin_settings_repository.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._repository) : super(const SettingsState.initial());

  final AdminSettingsRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: SettingsStatus.loading));
    final store = await _repository.getStoreSettings();
    final rc = await _repository.fetchRemoteMaintenanceMode();
    store.fold(
      (f) => emit(state.copyWith(status: SettingsStatus.failure, errorMessage: f.message)),
      (s) {
        rc.fold(
          (f2) => emit(state.copyWith(
            status: SettingsStatus.success,
            settings: s,
            remoteMaintenance: false,
            errorMessage: f2.message,
          )),
          (rm) => emit(state.copyWith(
            status: SettingsStatus.success,
            settings: s,
            remoteMaintenance: rm,
          )),
        );
      },
    );
  }

  void updateDraft(StoreSettingsEntity s) {
    emit(state.copyWith(settings: s));
  }

  Future<void> save() async {
    if (state.settings == null) return;
    emit(state.copyWith(status: SettingsStatus.saving));
    final result = await _repository.saveStoreSettings(state.settings!);
    result.fold(
      (f) => emit(state.copyWith(status: SettingsStatus.failure, errorMessage: f.message)),
      (_) => emit(state.copyWith(status: SettingsStatus.saved)),
    );
    await load();
  }
}
