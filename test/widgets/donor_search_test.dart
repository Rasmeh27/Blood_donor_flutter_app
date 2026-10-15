import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_laboratorio_intec/src/general/utils/date_format.dart';
import 'package:proyecto_laboratorio_intec/src/models/blood_request.dart';
import 'package:proyecto_laboratorio_intec/src/screens/views/donor_search/screens/donor_search_screen.dart';
import 'package:proyecto_laboratorio_intec/src/screens/views/donor_search/widgets/donor_result_item.dart';
import 'package:proyecto_laboratorio_intec/src/screens/views/edit_profile/screens/edit_profile_screen.dart';

import '../support/fake_backend.dart';
import '../support/widget_helpers.dart';

Map<String, dynamic> donorResultJson(int id, String bloodGroup) => {
      'id': id,
      'name': 'Donante $id',
      'bloodGroup': bloodGroup,
      'location': 'Santiago',
      'lastDonationDate': '2026-06-01',
    };

void main() {
  late FakeBackend backend;

  setUp(() => backend = FakeBackend());

  group('DonorSearchScreen', () {
    testWidgets('busca con el grupo recibido y muestra solo datos públicos', (tester) async {
      backend.handler = (request) => FakeBackend.json(
          pageJson([donorResultJson(1, request.url.queryParameters['bloodGroup'] ?? 'A+')]), 200);
      await installServices(backend, loggedIn: true);
      await pumpApp(tester, const DonorSearchScreen(), arguments: 'AB+');

      expect(backend.requests.single.url.query, contains('bloodGroup=AB%2B'));
      expect(find.byType(DonorResultItem), findsOneWidget);
      expect(find.text('Donante 1'), findsOneWidget);
      expect(find.text('Santiago'), findsOneWidget);
      expect(find.text('Last donation: 1 June 2026'), findsOneWidget);
      expect(find.textContaining('809'), findsNothing);
    });

    testWidgets('el filtro cambia el grupo y "All" lo quita', (tester) async {
      backend.handler = (request) => FakeBackend.json(pageJson([donorResultJson(1, 'O-')]), 200);
      await installServices(backend, loggedIn: true);
      await pumpApp(tester, const DonorSearchScreen(), arguments: 'O-');

      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      expect(backend.requests.last.url.queryParameters.containsKey('bloodGroup'), isFalse);

      await tester.tap(find.text('B+'));
      await tester.pumpAndSettle();
      expect(backend.requests.last.url.query, contains('bloodGroup=B%2B'));
    });

    testWidgets('sin donantes que autorizaron aparecer muestra un mensaje', (tester) async {
      backend.handler = (_) => FakeBackend.json(pageJson([]), 200);
      await installServices(backend, loggedIn: true);
      await pumpApp(tester, const DonorSearchScreen(), arguments: 'O-');

      expect(find.byType(DonorResultItem), findsNothing);
      expect(find.text('No donors available for this blood group yet.'), findsOneWidget);
    });
  });

  group('Consentimiento en Edit Profile', () {
    Map<String, dynamic> donorJson({required bool visible}) => {
          'id': 1,
          'name': 'Ana',
          'contactNumber': '+18092249304',
          'bloodGroup': 'B+',
          'location': 'Santiago',
          'lastDonationDate': '2026-06-01',
          'visibleInSearch': visible,
        };

    testWidgets('un donante puede autorizar aparecer en la búsqueda', (tester) async {
      backend.handler = (request) {
        if (request.url.path.endsWith('/users/me')) return FakeBackend.json(userJson(), 200);
        if (request.url.path.endsWith('/visibility')) return FakeBackend.json(donorJson(visible: true), 200);
        return FakeBackend.json(donorJson(visible: false), 200);
      };
      await installServices(backend, loggedIn: true);
      await pumpPushed(tester, const EditProfileScreen());

      final consent = find.byType(Switch);
      expect(tester.widget<Switch>(consent).value, isFalse);
      await tester.ensureVisible(consent);
      await tester.tap(consent);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final request = backend.requestsTo('PATCH', '/donors/me/visibility').single;
      expect(jsonDecode(request.body), {'visibleInSearch': true});
    });

    testWidgets('quien no es donante no ve la opción', (tester) async {
      backend.handler = (request) => request.url.path.endsWith('/users/me')
          ? FakeBackend.json(userJson(), 200)
          : FakeBackend.error(404, 'NOT_FOUND', 'El usuario no está registrado como donante');
      await installServices(backend, loggedIn: true);
      await pumpApp(tester, const EditProfileScreen());

      expect(find.byType(Switch), findsNothing);
    });

    testWidgets('si no cambia el consentimiento no se envía', (tester) async {
      backend.handler = (request) => request.url.path.endsWith('/users/me')
          ? FakeBackend.json(userJson(), 200)
          : FakeBackend.json(donorJson(visible: true), 200);
      await installServices(backend, loggedIn: true);
      await pumpPushed(tester, const EditProfileScreen());

      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(backend.requestsTo('PATCH', '/donors/me/visibility'), isEmpty);
    });
  });

  group('Fechas y zona horaria', () {
    test('los timestamps UTC se convierten a hora local y las fechas de calendario no', () {
      final request = BloodRequest.fromJson({
        ...bloodRequestJson(),
        'createdAt': '2026-10-14T22:27:06.293918Z',
        'needBefore': '2026-10-20',
      });

      expect(request.createdAt.isUtc, isFalse);
      expect(request.createdAt.toUtc(), DateTime.utc(2026, 10, 14, 22, 27, 6, 293, 918));
      // La fecha límite es un día de calendario: se mantiene el 20 sin importar la zona
      expect(request.needBefore, DateTime(2026, 10, 20));
      expect(toApiDate(request.needBefore), '2026-10-20');
    });

    test('el tiempo relativo usa el instante exacto', () {
      final created = parseTimestamp('2026-10-14T22:00:00Z');
      final now = DateTime.utc(2026, 10, 14, 22, 5).toLocal();

      expect(timeAgo(created, now: now), '5 minute ago');
    });
  });
}
