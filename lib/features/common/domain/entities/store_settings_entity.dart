import 'package:equatable/equatable.dart';

class StoreSettingsEntity extends Equatable {
  const StoreSettingsEntity({
    required this.deliveryCharge,
    required this.taxPercent,
    this.supportEmail,
    this.supportPhone,
    this.supportAddress,
    this.maintenanceMode = false,
  });

  final double deliveryCharge;
  final double taxPercent;
  final String? supportEmail;
  final String? supportPhone;
  final String? supportAddress;
  final bool maintenanceMode;

  @override
  List<Object?> get props => [
        deliveryCharge,
        taxPercent,
        supportEmail,
        supportPhone,
        supportAddress,
        maintenanceMode,
      ];
}
