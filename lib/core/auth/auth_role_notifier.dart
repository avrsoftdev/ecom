import 'package:flutter/foundation.dart';

/// Holds the Firestore `users/{uid}.role` for the signed-in user so [GoRouter]
/// redirects can run synchronously after [AuthCubit] loads the profile.
class AuthRoleNotifier extends ChangeNotifier {
  AuthRoleNotifier._();
  static final AuthRoleNotifier instance = AuthRoleNotifier._();

  String? _role;

  String? get role => _role;

  void setRole(String? role) {
    if (_role == role) return;
    _role = role;
    notifyListeners();
  }

  void clear() {
    setRole(null);
  }

  bool get isAdmin => _role == 'admin';
}
