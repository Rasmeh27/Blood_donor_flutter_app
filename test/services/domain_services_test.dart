import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_laboratorio_intec/src/general/utils/date_format.dart';
import 'package:proyecto_laboratorio_intec/src/models/blood_request.dart';
import 'package:proyecto_laboratorio_intec/src/models/gender.dart';
import 'package:proyecto_laboratorio_intec/src/services/api/api_exception.dart';

import '../support/fake_backend.dart';

void main() {
  group('UserApiService', () {
    test('consulta el perfil y actualiza el usuario en sesión', () async {
      final backend = FakeBackend((_) => FakeBackend.json(userJson(location: 'Santiago'), 200));
      final services = await installServices(backend, loggedIn: true);

      final user = await services.users.getCurrentUser();

      expect(user.location, 'Santiago');
      expect(services.session.currentUser?.location, 'Santiago');
      expect(backend.requests.single.url.path, '/api/v1/users/me');
    });

    test('actualiza solo los campos indicados con PATCH /users/me', () async {
      final backend = FakeBackend((_) => FakeBackend.json(userJson(name: 'Ana P.'), 200));
      final services = await installServices(backend, loggedIn: true);

      await services.users.updateCurrentUser(name: 'Ana P.', gender: Gender.female);

      final request = backend.requests.single;
      expect(request.method, 'PATCH');
      expect(request.url.path, '/api/v1/users/me');
      expect(jsonDecode(request.body), {'name': 'Ana P.', 'gender': 'FEMALE'});
    });

    test('401 al consultar el perfil cierra la sesión', () async {
      final backend = FakeBackend((_) => FakeBackend.error(401, 'UNAUTHORIZED', 'El token es inválido o ha expirado'));
      final services = await installServices(backend, loggedIn: true);

      await expectLater(services.users.getCurrentUser(), throwsA(isA<ApiException>()));
      expect(services.session.isActive, isFalse);
    });
  });

  group('DonorApiService', () {
    test('devuelve null cuando el usuario aún no es donante (404)', () async {
      final backend = FakeBackend((_) => FakeBackend.error(404, 'NOT_FOUND', 'El usuario no está registrado como donante'));
      final services = await installServices(backend, loggedIn: true);

      expect(await services.donors.getMyDonor(), isNull);
    });

    test('distingue registro (201) de actualización (200) y envía la fecha yyyy-MM-dd', () async {
      final donorJson = {
        'id': 1,
        'name': 'Ana',
        'contactNumber': '+18092249304',
        'bloodGroup': 'B+',
        'location': 'Santo Domingo, RD',
        'lastDonationDate': '2026-06-01',
      };
      final backend = FakeBackend((_) => FakeBackend.json(donorJson, 201));
      final services = await installServices(backend, loggedIn: true);

      Future<bool> save() async => (await services.donors.saveMyDonor(
            name: 'Ana',
            contactNumber: '+18092249304',
            bloodGroup: 'B+',
            location: 'Santo Domingo, RD',
            lastDonationDate: DateTime(2026, 6, 1),
          ))
              .created;

      expect(await save(), isTrue);
      backend.handler = (_) => FakeBackend.json(donorJson, 200);
      expect(await save(), isFalse);

      final body = jsonDecode(backend.requests.first.body) as Map<String, dynamic>;
      expect(backend.requests.first.method, 'PUT');
      expect(body['lastDonationDate'], '2026-06-01');
      expect(body.keys, unorderedEquals(['name', 'contactNumber', 'bloodGroup', 'location', 'lastDonationDate']));
    });

    test('propaga los errores de validación', () async {
      final backend = FakeBackend((_) => FakeBackend.error(400, 'VALIDATION_ERROR', 'Los datos enviados no son válidos',
          fields: [{'field': 'lastDonationDate', 'message': 'La fecha de la última donación no puede ser futura'}]));
      final services = await installServices(backend, loggedIn: true);

      await expectLater(
        services.donors.saveMyDonor(
            name: 'Ana', contactNumber: '8090000000', bloodGroup: 'A+', location: 'X', lastDonationDate: DateTime(2099)),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('futura'))),
      );
    });
  });

  group('BloodRequestApiService', () {
    test('crea la solicitud con los valores recibidos', () async {
      final backend = FakeBackend((_) => FakeBackend.json(bloodRequestJson(), 201));
      final services = await installServices(backend, loggedIn: true);

      final created = await services.bloodRequests.create(NewBloodRequest(
        bloodGroup: 'AB+',
        bags: 2,
        contactNumber: '+18092249304',
        emergencyContact: '+18095550000',
        patientName: 'Jorge Perez',
        caseDescription: 'Cancer Patient',
        patientGender: Gender.male,
        needBefore: DateTime(2026, 10, 20),
        others: 'Need very urgent',
      ));

      expect(created.id, 1);
      expect(jsonDecode(backend.requests.single.body), {
        'bloodGroup': 'AB+',
        'bags': 2,
        'contactNumber': '+18092249304',
        'emergencyContact': '+18095550000',
        'patientName': 'Jorge Perez',
        'caseDescription': 'Cancer Patient',
        'patientGender': 'MALE',
        'needBefore': '2026-10-20',
        'others': 'Need very urgent',
      });
    });

    test('lista, filtra por grupo y pagina', () async {
      final backend = FakeBackend(
          (_) => FakeBackend.json(pageJson([bloodRequestJson(id: 1), bloodRequestJson(id: 2)], totalPages: 3), 200));
      final services = await installServices(backend, loggedIn: true);

      final page = await services.bloodRequests.list(bloodGroup: 'O-', page: 1);

      expect(page.items.map((r) => r.id), [1, 2]);
      expect(page.hasMore, isTrue);
      expect(backend.requests.single.url.queryParameters, {'bloodGroup': 'O-', 'page': '1', 'size': '10'});
    });

    test('lista vacía no genera elementos', () async {
      final backend = FakeBackend((_) => FakeBackend.json(pageJson([]), 200));
      final services = await installServices(backend, loggedIn: true);

      final page = await services.bloodRequests.list();

      expect(page.items, isEmpty);
      expect(page.hasMore, isFalse);
      expect(backend.requests.single.url.queryParameters.containsKey('bloodGroup'), isFalse);
    });

    test('consulta el detalle por id y conserva la ubicación nula', () async {
      final backend = FakeBackend((_) => FakeBackend.json(bloodRequestJson(id: 15), 200));
      final services = await installServices(backend, loggedIn: true);

      final detail = await services.bloodRequests.getById(15);

      expect(backend.requests.single.url.path, '/api/v1/blood-requests/15');
      expect(detail.location, isNull);
      expect(detail.needBefore, DateTime(2026, 10, 20));
    });
  });

  group('Fechas', () {
    test('formatos de API, tarjetas y tiempo relativo', () {
      expect(toApiDate(DateTime(2026, 6, 1)), '2026-06-01');
      expect(parseApiDate('2026-06-01'), DateTime(2026, 6, 1));
      expect(toLongDate(DateTime(2024, 2, 10)), '10 February 2024');
      expect(toPickerDate(DateTime(2024, 2, 10)), '10-2-2024');

      final now = DateTime(2026, 10, 14, 12);
      expect(timeAgo(now.subtract(const Duration(seconds: 20)), now: now), 'just now');
      expect(timeAgo(now.subtract(const Duration(minutes: 2)), now: now), '2 minute ago');
      expect(timeAgo(now.subtract(const Duration(hours: 3)), now: now), '3 hour ago');
      expect(timeAgo(now.subtract(const Duration(days: 4)), now: now), '4 day ago');
    });
  });
}
