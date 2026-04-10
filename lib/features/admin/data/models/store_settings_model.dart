import '../../../common/domain/entities/store_settings_entity.dart';

class StoreSettingsModel extends StoreSettingsEntity {
  const StoreSettingsModel({
    required super.deliveryCharge,
    required super.taxPercent,
    super.supportEmail,
    super.supportPhone,
    super.supportAddress,
    super.maintenanceMode = false,
  });

  factory StoreSettingsModel.fromJson(Map<String, dynamic> json) {
    return StoreSettingsModel(
      deliveryCharge: (json['deliveryCharge'] as num?)?.toDouble() ?? 0,
      taxPercent: (json['taxPercent'] as num?)?.toDouble() ?? 0,
      supportEmail: json['supportEmail'] as String?,
      supportPhone: json['supportPhone'] as String?,
      supportAddress: json['supportAddress'] as String?,
      maintenanceMode: json['maintenanceMode'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'deliveryCharge': deliveryCharge,
        'taxPercent': taxPercent,
        'supportEmail': supportEmail,
        'supportPhone': supportPhone,
        'supportAddress': supportAddress,
        'maintenanceMode': maintenanceMode,
      };
}
