import 'package:firebase_auth/firebase_auth.dart';

class AuthUserModel {
  const AuthUserModel({
    required this.uid,
    required this.email,
    required this.providerIds,
    this.displayName,
    this.photoUrl,
    this.phone,
    this.address,
    this.role,
  });

  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? phone;
  final String? address;
  /// Firestore `users` document role: `admin` or `customer` (default).
  final String? role;
  final List<String> providerIds;

  factory AuthUserModel.fromFirebaseUser(User user) {
    return AuthUserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      providerIds: user.providerData
          .map((provider) => provider.providerId)
          .where((providerId) => providerId.isNotEmpty)
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'display_name': displayName,
      'photo_url': photoUrl,
      'phone': phone,
      'address': address,
      'provider_ids': providerIds,
      if (role != null) 'role': role,
    };
  }
}
