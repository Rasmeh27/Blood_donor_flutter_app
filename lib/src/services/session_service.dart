import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user_profile.dart';

/// Guarda el JWT y los datos públicos del usuario en almacenamiento cifrado
/// (Keystore de Android) y mantiene una copia en memoria para lecturas síncronas.
class SessionService {
  static const _tokenKey = 'auth_token';
  static const _expiresAtKey = 'auth_expires_at';
  static const _userKey = 'auth_user';

  // El token se considera vencido un poco antes para no enviar uno que expire en tránsito
  static const _expirationMargin = Duration(seconds: 30);

  final FlutterSecureStorage _storage;
  final DateTime Function() _now;

  String? _token;
  DateTime? _expiresAt;
  UserProfile? _currentUser;

  SessionService({FlutterSecureStorage? storage, DateTime Function()? now})
      : _storage = storage ?? const FlutterSecureStorage(),
        _now = now ?? DateTime.now;

  UserProfile? get currentUser => _currentUser;

  bool get isActive =>
      _token != null &&
      _expiresAt != null &&
      _now().isBefore(_expiresAt!.subtract(_expirationMargin));

  /// Token listo para enviar, o null si no hay sesión o ya venció.
  String? get validToken => isActive ? _token : null;

  /// Recupera la sesión guardada al abrir la aplicación.
  Future<void> restore() async {
    final values = await _storage.readAll();
    _token = values[_tokenKey];
    _expiresAt = DateTime.tryParse(values[_expiresAtKey] ?? '');
    final userJson = values[_userKey];
    _currentUser = userJson == null
        ? null
        : UserProfile.fromJson(jsonDecode(userJson) as Map<String, dynamic>);

    if (!isActive) {
      await clear();
    }
  }

  Future<void> save({
    required String token,
    required DateTime expiresAt,
    required UserProfile user,
  }) async {
    _token = token;
    _expiresAt = expiresAt;
    _currentUser = user;
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _expiresAtKey, value: expiresAt.toUtc().toIso8601String());
    await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  Future<void> updateUser(UserProfile user) async {
    _currentUser = user;
    await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  Future<void> clear() async {
    _token = null;
    _expiresAt = null;
    _currentUser = null;
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _expiresAtKey);
    await _storage.delete(key: _userKey);
  }
}
