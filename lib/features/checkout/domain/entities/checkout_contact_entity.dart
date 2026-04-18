import 'package:equatable/equatable.dart';

class CheckoutContactEntity extends Equatable {
  final String name;
  final String address;
  final String landmark;
  final String phoneNumber;
  final bool isForSelf;

  const CheckoutContactEntity({
    required this.name,
    required this.address,
    required this.landmark,
    required this.phoneNumber,
    required this.isForSelf,
  });

  factory CheckoutContactEntity.empty() {
    return const CheckoutContactEntity(
      name: '',
      address: '',
      landmark: '',
      phoneNumber: '',
      isForSelf: true,
    );
  }

  CheckoutContactEntity copyWith({
    String? name,
    String? address,
    String? landmark,
    String? phoneNumber,
    bool? isForSelf,
  }) {
    return CheckoutContactEntity(
      name: name ?? this.name,
      address: address ?? this.address,
      landmark: landmark ?? this.landmark,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isForSelf: isForSelf ?? this.isForSelf,
    );
  }

  @override
  List<Object?> get props => [name, address, landmark, phoneNumber, isForSelf];
}
