import '../models/user_profile.dart';
import '../repositories/auth_repository.dart';
import 'api/api_client.dart';
import 'api/api_exception.dart';
import 'session_service.dart';

/// Autenticación contra Spring Boot (reemplaza a AuthServiceFirebase).
class AuthServiceApi implements AuthRepository {
  static const success = 'Success';

  final ApiClient _apiClient;
  final SessionService _session;

  AuthServiceApi(this._apiClient, this._session);

  @override
  Future<String> login({required String email, required String password}) async {
    try {
      final response = await _apiClient.post(
        '/auth/login',
        authenticated: false,
        body: {'email': email, 'password': password},
      );

      await _session.save(
        token: response.body['accessToken'] as String,
        expiresAt: DateTime.parse(response.body['expiresAt'] as String),
        user: UserProfile.fromJson(response.body['user'] as Map<String, dynamic>),
      );
      return success;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  @override
  Future<String> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      await _apiClient.post(
        '/auth/register',
        authenticated: false,
        body: {'name': name, 'email': email, 'password': password},
      );
      return success;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  // Siempre responde igual exista o no la cuenta; el código llega por correo
  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _apiClient.post(
      '/auth/password/forgot',
      authenticated: false,
      body: {'email': email},
    );
  }

  @override
  Future<void> verifyResetCode({required String email, required String code}) async {
    await _apiClient.post(
      '/auth/password/verify',
      authenticated: false,
      body: {'email': email, 'code': code},
    );
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _apiClient.post(
      '/auth/password/reset',
      authenticated: false,
      body: {'email': email, 'code': code, 'newPassword': newPassword},
    );
  }

  // El JWT no tiene estado en el servidor: cerrar sesión es eliminar el token local
  @override
  Future<void> logout() => _session.clear();
}
