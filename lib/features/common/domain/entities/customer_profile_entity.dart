import 'package:equatable/equatable.dart';

class CustomerProfileEntity extends Equatable {
  const CustomerProfileEntity({
    required this.id,
    required this.email,
    this.displayName,
    this.phone,
    this.address,
    this.photoUrl,
    required this.role,
    required this.createdAt,
    this.lastSignInAt,
  });

  final String id;
  final String email;
  final String? displayName;
  final String? phone;
  final String? address;
  final String? photoUrl;
  final String role;
  final DateTime createdAt;
  final DateTime? lastSignInAt;

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        phone,
        address,
        photoUrl,
        role,
        createdAt,
        lastSignInAt,
      ];
}
