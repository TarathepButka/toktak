// features/auth/data/datasources/auth_remote_datasource.dart
import 'package:toktak/features/auth/data/models/user_model.dart';

/// Contract for all remote auth operations.
/// The implementation talks to the backend via Dio.
abstract class AuthRemoteDataSource {
  /// Exchanges a Google ID token for app access + refresh tokens.
  Future<AuthResponse> loginWithGoogle(String idToken);

  /// Exchanges a LINE access token for app access + refresh tokens.
  Future<AuthResponse> loginWithLine(String accessToken);
}
