/// Legacy HTTP auth client pointing at a placeholder backend.
///
/// Farmora uses FirebaseAuthService exclusively. Do not call this from product code.
@Deprecated('Use FirebaseAuthService — kku-backend.example.com is not a real API')
library;

import '../../models/user_role.dart';

@Deprecated('Use FirebaseAuthService instead of this dead HTTP stub')
class AuthService {
  AuthService();

  Future<bool> register({
    required String name,
    required String phone,
    required String password,
    required Role role,
    String? district,
  }) async {
    throw UnsupportedError(
      'AuthService is quarantined. Use FirebaseAuthService for Farmora authentication.',
    );
  }

  Future<String?> login({
    required String phone,
    required String password,
  }) async {
    throw UnsupportedError(
      'AuthService is quarantined. Use FirebaseAuthService for Farmora authentication.',
    );
  }
}
