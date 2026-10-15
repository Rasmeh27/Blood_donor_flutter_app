import '../models/gender.dart';
import '../models/user_profile.dart';
import 'api/api_client.dart';
import 'session_service.dart';

/// Perfil del usuario autenticado. El backend lo identifica por el JWT, nunca por un id enviado.
class UserApiService {
  final ApiClient _apiClient;
  final SessionService _session;

  UserApiService(this._apiClient, this._session);

  Future<UserProfile> getCurrentUser() async {
    final response = await _apiClient.get('/users/me');
    final user = UserProfile.fromJson(response.body);
    await _session.updateUser(user);
    return user;
  }

  /// Actualización parcial: solo se envían los campos indicados.
  Future<UserProfile> updateCurrentUser({
    String? name,
    String? phone,
    Gender? gender,
    String? location,
  }) async {
    final response = await _apiClient.patch('/users/me', body: {
      'name': ?name,
      'phone': ?phone,
      'gender': ?gender?.apiValue,
      'location': ?location,
    });
    final user = UserProfile.fromJson(response.body);
    await _session.updateUser(user);
    return user;
  }
}
