import 'package:equatable/equatable.dart';

class CheckoutContactEntity extends Equatable {
  final String name;
  final String houseFlatBuilding;
  final String streetAreaColony;
  final String city;
  final String state;
  final String pincode;
  final String landmark;
  final String phoneNumber;
  final bool isForSelf;

  const CheckoutContactEntity({
    required this.name,
    required this.houseFlatBuilding,
    required this.streetAreaColony,
    required this.city,
    required this.state,
    required this.pincode,
    required this.landmark,
    required this.phoneNumber,
    required this.isForSelf,
  });

  factory CheckoutContactEntity.empty() {
    return const CheckoutContactEntity(
      name: '',
      houseFlatBuilding: '',
      streetAreaColony: '',
      city: '',
      state: '',
      pincode: '',
      landmark: '',
      phoneNumber: '',
      isForSelf: true,
    );
  }

  CheckoutContactEntity copyWith({
    String? name,
    String? houseFlatBuilding,
    String? streetAreaColony,
    String? city,
    String? state,
    String? pincode,
    String? landmark,
    String? phoneNumber,
    bool? isForSelf,
  }) {
    return CheckoutContactEntity(
      name: name ?? this.name,
      houseFlatBuilding: houseFlatBuilding ?? this.houseFlatBuilding,
      streetAreaColony: streetAreaColony ?? this.streetAreaColony,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      landmark: landmark ?? this.landmark,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isForSelf: isForSelf ?? this.isForSelf,
    );
  }

  // Helper method to get full address for backward compatibility
  String get fullAddress {
    return '$houseFlatBuilding, $streetAreaColony, $city, $state - $pincode';
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'houseFlatBuilding': houseFlatBuilding,
      'streetAreaColony': streetAreaColony,
      'city': city,
      'state': state,
      'pincode': pincode,
      'landmark': landmark,
      'phoneNumber': phoneNumber,
      'isForSelf': isForSelf,
    };
  }

  @override
  List<Object?> get props => [
        name,
        houseFlatBuilding,
        streetAreaColony,
        city,
        state,
        pincode,
        landmark,
        phoneNumber,
        isForSelf,
      ];
}
