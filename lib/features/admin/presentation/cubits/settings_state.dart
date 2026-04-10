part of 'settings_cubit.dart';

enum SettingsStatus { initial, loading, success, saving, saved, failure }

class SettingsState extends Equatable {
  const SettingsState({
    required this.status,
    this.settings,
    this.remoteMaintenance = false,
    this.errorMessage,
  });

  const SettingsState.initial() : this(status: SettingsStatus.initial);

  final SettingsStatus status;
  final StoreSettingsEntity? settings;
  final bool remoteMaintenance;
  final String? errorMessage;

  SettingsState copyWith({
    SettingsStatus? status,
    StoreSettingsEntity? settings,
    bool? remoteMaintenance,
    String? errorMessage,
  }) {
    return SettingsState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      remoteMaintenance: remoteMaintenance ?? this.remoteMaintenance,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, settings, remoteMaintenance, errorMessage];
}
