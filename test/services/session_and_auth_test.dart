import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_laboratorio_intec/src/services/api/api_exception.dart';
import 'package:proyecto_laboratorio_intec/src/services/session_service.dart';

import '../support/fake_backend.dart';

void main() {
  group('SessionService', () {
    test('guarda la sesión cifrada y la restaura al reiniciar la app', () async {
      FlutterSecureStorage.setMockInitialValues({});
      await SessionService().save(
        token: 'a.b.c',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        user: testUser,
      );

      final restarted = SessionService();
      await restarted.restore();

      expect(restarted.isActive, isTrue);
      expect(restarted.validToken, 'a.b.c');
      expect(restarted.currentUser?.name, 'Ana Perez');
    });

    test('descarta una sesión vencida al restaurar', () async {
      FlutterSecureStorage.setMockInitialValues({
        'auth_token': 'a.b.c',
        'auth_expires_at': DateTime.now().subtract(const Duration(minutes: 1)).toUtc().toIso8601String(),
        'auth_user': jsonEncode(testUser.toJson()),
      });

      final session = SessionService();
      await session.restore();

      expect(session.isActive, isFalse);
      expect(session.validToken, isNull);
      expect(await const FlutterSecureStorage().read(key: 'auth_token'), isNull);
    });

    test('considera vencido el token que expira en los próximos segundos', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final session = SessionService();
      await session.save(
        token: 'a.b.c',
        expiresAt: DateTime.now().add(const Duration(seconds: 10)),
        user: testUser,
      );

      expect(session.isActive, isFalse);
    });

    test('clear elimina el token del almacenamiento', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final session = SessionService();
      await session.save(token: 'a.b.c', expiresAt: DateTime.now().add(const Duration(hours: 1)), user: testUser);

      await session.clear();

      expect(session.isActive, isFalse);
      expect(await const FlutterSecureStorage().readAll(), isEmpty);
    });
  });

  group('AuthServiceApi', () {
    test('login correcto guarda token, expiración y usuario', () async {
      final backend = FakeBackend((_) => FakeBackend.json({
            'tokenType': 'Bearer',
            'accessToken': 'jwt.real.token',
            'expiresAt': DateTime.now().add(const Duration(hours: 1)).toUtc().toIso8601String(),
            'user': userJson(),
          }, 200));
      final services = await installServices(backend);

      final result = await services.auth.login(email: 'ana@mail.com', password: 'Secreta#123');

      expect(result, 'Success');
      expect(services.session.validToken, 'jwt.real.token');
      expect(services.session.currentUser?.email, 'ana@mail.com');
      expect(jsonDecode(backend.requests.single.body), {'email': 'ana@mail.com', 'password': 'Secreta#123'});
    });

    test('login con contraseña incorrecta devuelve el mensaje y no crea sesión', () async {
      final backend = FakeBackend((_) => FakeBackend.error(401, 'INVALID_CREDENTIALS', 'Correo o contraseña incorrectos'));
      final services = await installServices(backend);

      final result = await services.auth.login(email: 'ana@mail.com', password: 'Mala#1234');

      expect(result, 'Correo o contraseña incorrectos');
      expect(services.session.isActive, isFalse);
    });

    test('registro exitoso, duplicado y con validación fallida', () async {
      final backend = FakeBackend((_) => FakeBackend.json(userJson(), 201));
      final services = await installServices(backend);

      expect(await services.auth.register(name: 'Ana', email: 'ana@mail.com', password: 'Secreta#123'), 'Success');
      expect(backend.requests.single.url.path, '/api/v1/auth/register');

      backend.handler = (_) => FakeBackend.error(409, 'CONFLICT', 'El correo ya esta registrado');
      expect(await services.auth.register(name: 'Ana', email: 'ana@mail.com', password: 'Secreta#123'),
          'El correo ya esta registrado');

      backend.handler = (_) => FakeBackend.error(400, 'VALIDATION_ERROR', 'Los datos enviados no son válidos',
          fields: [{'field': 'email', 'message': 'El correo no es válido'}]);
      expect(await services.auth.register(name: 'Ana', email: 'x', password: 'Secreta#123'), 'El correo no es válido');
    });

    test('logout elimina la sesión local', () async {
      final services = await installServices(FakeBackend(), loggedIn: true);

      await services.auth.logout();

      expect(services.session.isActive, isFalse);
    });

    test('recuperación: solicita código, verifica y restablece con los endpoints públicos', () async {
      final backend = FakeBackend((request) => request.url.path.endsWith('/forgot')
          ? FakeBackend.json({'message': 'Si el correo está registrado, recibirás un código'}, 202)
          : FakeBackend.json({}, 204));
      final services = await installServices(backend);

      await services.auth.sendPasswordResetEmail('ana@mail.com');
      await services.auth.verifyResetCode(email: 'ana@mail.com', code: '123456');
      await services.auth.resetPassword(email: 'ana@mail.com', code: '123456', newPassword: 'Nueva#2026');

      expect(backend.requests.map((r) => r.url.path), [
        '/api/v1/auth/password/forgot',
        '/api/v1/auth/password/verify',
        '/api/v1/auth/password/reset',
      ]);
      expect(backend.requests.every((r) => !r.headers.containsKey('Authorization')), isTrue);
      expect(jsonDecode(backend.requests.last.body),
          {'email': 'ana@mail.com', 'code': '123456', 'newPassword': 'Nueva#2026'});
    });

    test('código inválido y exceso de solicitudes llegan como mensajes legibles', () async {
      final backend = FakeBackend((_) => FakeBackend.error(400, 'INVALID_RESET_CODE', 'El código es inválido o ha expirado'));
      final services = await installServices(backend);

      await expectLater(services.auth.verifyResetCode(email: 'ana@mail.com', code: '000000'),
          throwsA(isA<ApiException>().having((e) => e.message, 'message', 'El código es inválido o ha expirado')));

      backend.handler = (_) => FakeBackend.error(429, 'TOO_MANY_REQUESTS', 'Espera antes de solicitar otro código');
      await expectLater(services.auth.sendPasswordResetEmail('ana@mail.com'),
          throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Espera antes de solicitar otro código')));
    });
  });
}
