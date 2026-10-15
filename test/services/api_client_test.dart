import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:proyecto_laboratorio_intec/src/services/api/api_client.dart';
import 'package:proyecto_laboratorio_intec/src/services/api/api_exception.dart';

import '../support/fake_backend.dart';

void main() {
  late FakeBackend backend;

  setUp(() => backend = FakeBackend());

  Future<ApiClient> clientWithSession({bool loggedIn = true}) async {
    final services = await installServices(backend, loggedIn: loggedIn);
    return services.apiClient;
  }

  test('envía JSON, Accept y Bearer token en peticiones autenticadas', () async {
    backend.handler = (_) => FakeBackend.json({'ok': true}, 200);
    final client = await clientWithSession();

    final response = await client.post('/blood-requests', body: {'bags': 2});

    final request = backend.requests.single;
    expect(response.statusCode, 200);
    expect(request.headers['Authorization'], 'Bearer header.payload.signature');
    expect(request.headers['Content-Type'], startsWith('application/json'));
    expect(request.headers['Accept'], 'application/json');
    expect(request.body, '{"bags":2}');
    expect(request.url.toString(), 'http://10.0.2.2:8080/api/v1/blood-requests');
  });

  test('no envía token en peticiones públicas', () async {
    backend.handler = (_) => FakeBackend.json({}, 201);
    final client = await clientWithSession(loggedIn: false);

    await client.post('/auth/register', body: {}, authenticated: false);

    expect(backend.requests.single.headers.containsKey('Authorization'), isFalse);
  });

  test('codifica el + del grupo sanguíneo como %2B', () async {
    backend.handler = (_) => FakeBackend.json({}, 200);
    final client = await clientWithSession();

    await client.get('/blood-requests', query: {'bloodGroup': 'A+', 'page': '0'});

    expect(backend.requests.single.url.query, 'bloodGroup=A%2B&page=0');
  });

  test('400 expone el primer mensaje de campo del backend', () async {
    backend.handler = (_) => FakeBackend.error(400, 'VALIDATION_ERROR', 'Los datos enviados no son válidos',
        fields: [{'field': 'bags', 'message': 'Debe solicitar al menos 1 bolsa'}]);
    final client = await clientWithSession();

    final error = await _captureError(() => client.post('/blood-requests', body: {}));

    expect(error.type, ApiErrorType.validation);
    expect(error.message, 'Debe solicitar al menos 1 bolsa');
    expect(error.fields.single.field, 'bags');
  });

  test('401 con token cierra la sesión y avisa', () async {
    backend.handler = (_) => FakeBackend.error(401, 'UNAUTHORIZED', 'El token es inválido o ha expirado');
    final services = await installServices(backend, loggedIn: true);
    var expiredCalls = 0;
    services.apiClient.onSessionExpired = () => expiredCalls++;

    final error = await _captureError(() => services.apiClient.get('/users/me'));

    expect(error.type, ApiErrorType.sessionExpired);
    expect(services.session.isActive, isFalse);
    expect(expiredCalls, 1);
  });

  test('401 de credenciales en el login no se trata como sesión vencida', () async {
    backend.handler = (_) => FakeBackend.error(401, 'INVALID_CREDENTIALS', 'Correo o contraseña incorrectos');
    final services = await installServices(backend, loggedIn: true);
    var expiredCalls = 0;
    services.apiClient.onSessionExpired = () => expiredCalls++;

    final error = await _captureError(
        () => services.apiClient.post('/auth/login', body: {}, authenticated: false));

    expect(error.type, ApiErrorType.invalidCredentials);
    expect(error.message, 'Correo o contraseña incorrectos');
    expect(services.session.isActive, isTrue);
    expect(expiredCalls, 0);
  });

  test('403 no elimina la sesión', () async {
    backend.handler = (_) => FakeBackend.error(403, 'FORBIDDEN', 'No tiene permiso');
    final services = await installServices(backend, loggedIn: true);

    final error = await _captureError(() => services.apiClient.get('/users/1'));

    expect(error.type, ApiErrorType.forbidden);
    expect(services.session.isActive, isTrue);
  });

  test('sin sesión válida no llega a enviar la petición', () async {
    final client = await clientWithSession(loggedIn: false);

    final error = await _captureError(() => client.get('/users/me'));

    expect(error.type, ApiErrorType.sessionExpired);
    expect(backend.requests, isEmpty);
  });

  test('404, 409 y 500 se traducen sin exponer detalles internos', () async {
    final client = await clientWithSession();

    backend.handler = (_) => FakeBackend.error(404, 'NOT_FOUND', 'Solicitud de sangre no encontrada');
    expect((await _captureError(() => client.get('/blood-requests/9'))).type, ApiErrorType.notFound);

    backend.handler = (_) => FakeBackend.error(409, 'CONFLICT', 'El correo ya esta registrado');
    final conflict = await _captureError(() => client.post('/auth/register', body: {}, authenticated: false));
    expect(conflict.type, ApiErrorType.conflict);
    expect(conflict.message, 'El correo ya esta registrado');

    backend.handler = (_) => FakeBackend.error(500, 'INTERNAL_ERROR', 'java.sql.SQLException: detalle interno');
    final server = await _captureError(() => client.get('/users/me'));
    expect(server.type, ApiErrorType.server);
    expect(server.message, isNot(contains('SQL')));
  });

  test('respuesta que no es JSON se informa como respuesta inválida', () async {
    backend.handler = (_) => http.Response('<html>proxy</html>', 200);
    final client = await clientWithSession();

    expect((await _captureError(() => client.get('/users/me'))).type, ApiErrorType.invalidResponse);
  });

  test('sin conexión y timeout producen errores de red sin cerrar la sesión', () async {
    final services = await installServices(backend, loggedIn: true);

    backend.handler = (_) => throw const SocketException('Connection refused');
    expect((await _captureError(() => services.apiClient.get('/users/me'))).type, ApiErrorType.network);

    backend.handler = (_) => throw http.ClientException('Connection closed');
    expect((await _captureError(() => services.apiClient.get('/users/me'))).type, ApiErrorType.network);

    final slowClient = ApiClient(
      httpClient: FakeBackend((_) => throw TimeoutException('lento')).client,
      session: services.session,
    );
    expect((await _captureError(() => slowClient.get('/users/me'))).type, ApiErrorType.timeout);

    expect(services.session.isActive, isTrue);
  });
}

Future<ApiException> _captureError(Future<Object?> Function() action) async {
  try {
    await action();
  } on ApiException catch (error) {
    return error;
  }
  fail('Se esperaba una ApiException');
}
