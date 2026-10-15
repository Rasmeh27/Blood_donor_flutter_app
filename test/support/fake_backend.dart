import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:proyecto_laboratorio_intec/src/models/user_profile.dart';
import 'package:proyecto_laboratorio_intec/src/services/app_services.dart';
import 'package:proyecto_laboratorio_intec/src/services/session_service.dart';

/// Backend simulado para pruebas unitarias y de widgets: registra cada petición y
/// responde según el manejador de la prueba. La app real nunca usa esta clase.
class FakeBackend {
  final List<http.Request> requests = [];
  FutureOr<http.Response> Function(http.Request request) handler;

  FakeBackend([FutureOr<http.Response> Function(http.Request request)? handler])
      : handler = handler ?? ((_) => json({}, 404));

  late final http.Client client = MockClient((request) async {
    requests.add(request);
    return await handler(request);
  });

  List<http.Request> requestsTo(String method, String path) =>
      requests.where((r) => r.method == method && r.url.path.endsWith(path)).toList();

  static http.Response json(Object body, int status) => http.Response.bytes(
        utf8.encode(jsonEncode(body)),
        status,
        headers: {'content-type': 'application/json'},
      );

  static http.Response error(int status, String error, String message,
          {List<Map<String, String>> fields = const []}) =>
      json({
        'status': status,
        'error': error,
        'message': message,
        'path': '/api/v1/test',
        if (fields.isNotEmpty) 'fields': fields,
      }, status);
}

const testUser = UserProfile(id: 7, name: 'Ana Perez', email: 'ana@mail.com');

Map<String, dynamic> userJson({String name = 'Ana Perez', String? location}) => {
      'id': 7,
      'name': name,
      'email': 'ana@mail.com',
      'phone': null,
      'gender': null,
      'location': location,
      'createdAt': '2026-10-14T22:27:03.936313Z',
    };

Map<String, dynamic> bloodRequestJson({int id = 1, String bloodGroup = 'AB+', String? location}) => {
      'id': id,
      'bloodGroup': bloodGroup,
      'bags': 2,
      'contactNumber': '+18092249304',
      'emergencyContact': '+18095550000',
      'patientName': 'Paciente $id',
      'caseDescription': 'Accident',
      'patientGender': 'MALE',
      'needBefore': '2026-10-20',
      'location': location,
      'others': 'Need very urgent',
      'createdAt': '2026-10-14T22:27:06.293918Z',
    };

Map<String, dynamic> pageJson(List<Map<String, dynamic>> items, {int page = 0, int totalPages = 1}) => {
      'content': items,
      'page': page,
      'size': 10,
      'totalElements': items.length,
      'totalPages': totalPages,
    };

/// Instala servicios que usan [backend]. Con [loggedIn] se guarda una sesión válida.
Future<AppServices> installServices(FakeBackend backend, {bool loggedIn = false}) async {
  FlutterSecureStorage.setMockInitialValues({});
  final session = SessionService();
  if (loggedIn) {
    await session.save(
      token: 'header.payload.signature',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      user: testUser,
    );
  }
  final services = AppServices.create(httpClient: backend.client, session: session);
  AppServices.instance = services;
  return services;
}
