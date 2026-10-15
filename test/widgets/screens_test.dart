import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:proyecto_laboratorio_intec/src/general/utils/date_format.dart';
import 'package:proyecto_laboratorio_intec/src/screens/views/all_request_details/screens/request_details_screen.dart';
import 'package:proyecto_laboratorio_intec/src/screens/views/all_requests/screens/all_request_screen.dart';
import 'package:proyecto_laboratorio_intec/src/screens/views/components/widgets/find_donor_date_picker.dart';
import 'package:proyecto_laboratorio_intec/src/screens/views/donor_registration/screens/donor_registration_screen.dart';
import 'package:proyecto_laboratorio_intec/src/screens/views/donor_search/screens/donor_search_screen.dart';
import 'package:proyecto_laboratorio_intec/src/screens/views/find_donor/screens/find_donor_screen.dart';
import 'package:proyecto_laboratorio_intec/src/screens/views/home/screens/home_screen.dart';
import 'package:proyecto_laboratorio_intec/src/screens/views/home/widgets/request_feed_item.dart';
import 'package:proyecto_laboratorio_intec/src/screens/views/profile/screens/profile_screen.dart';

import '../support/fake_backend.dart';
import '../support/widget_helpers.dart';

Finder fieldWithHint(String hint) => find.widgetWithText(TextField, hint);

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  // Un campo enfocado vuelve a desplazar la vista hacia sí mismo; se suelta el foco como al tocar fuera
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

// El SnackBar flotante puede cubrir el botón inferior del formulario
Future<void> dismissSnackBar(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

void main() {
  late FakeBackend backend;

  setUp(() => backend = FakeBackend());

  group('Home', () {
    testWidgets('muestra el indicador de carga y luego las solicitudes reales', (tester) async {
      final pending = Completer<http.Response>();
      backend.handler = (_) => pending.future;
      await installServices(backend, loggedIn: true);
      usePhoneSize(tester);
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      pending.complete(FakeBackend.json(
          pageJson([bloodRequestJson(id: 1, bloodGroup: 'O-'), bloodRequestJson(id: 2)]), 200));
      await tester.pumpAndSettle();

      expect(find.byType(CustomRequestFeedItem), findsNWidgets(2));
      expect(find.text('Paciente 1'), findsOneWidget);
      expect(find.text('O-'), findsOneWidget);
      expect(find.text('2 Bag | Accident'), findsNWidgets(2));
      expect(find.text('20 October 2026'), findsNWidgets(2));
      // Sin ubicación en la solicitud: no se inventa un valor
      expect(find.text('Santo Domingo, DN'), findsNothing);
      expect(backend.requests.single.url.queryParameters, {'page': '0', 'size': '10'});
    });

    testWidgets('lista vacía muestra un mensaje en lugar de tarjetas', (tester) async {
      backend.handler = (_) => FakeBackend.json(pageJson([]), 200);
      await installServices(backend, loggedIn: true);
      await pumpApp(tester, const HomeScreen());

      expect(find.byType(CustomRequestFeedItem), findsNothing);
      expect(find.text('There are no blood requests yet.'), findsOneWidget);
    });

    testWidgets('error de conexión permite reintentar', (tester) async {
      backend.handler = (_) => throw http.ClientException('Connection refused');
      await installServices(backend, loggedIn: true);
      await pumpApp(tester, const HomeScreen());

      expect(find.textContaining('Could not connect to the server'), findsOneWidget);

      backend.handler = (_) => FakeBackend.json(pageJson([bloodRequestJson()]), 200);
      await tapVisible(tester, find.text('Retry'));

      expect(find.byType(CustomRequestFeedItem), findsOneWidget);
    });

    testWidgets('Details abre el detalle de la solicitud correspondiente', (tester) async {
      backend.handler = (request) => request.url.path.endsWith('/blood-requests')
          ? FakeBackend.json(pageJson([bloodRequestJson(id: 42)]), 200)
          : FakeBackend.json(bloodRequestJson(id: 42), 200);
      await installServices(backend, loggedIn: true);
      await pumpApp(tester, const HomeScreen());

      await tapVisible(tester, find.text('Details'));

      expect(find.byType(RequestDetailsScreen), findsOneWidget);
      expect(backend.requestsTo('GET', '/blood-requests/42'), hasLength(1));
      expect(find.text('Paciente 42'), findsOneWidget);
      expect(find.text('2 Bags'), findsOneWidget);
      expect(find.text('—'), findsOneWidget); // ubicación ausente
    });

    testWidgets('el menú lateral navega a las pantallas', (tester) async {
      backend.handler = (request) => request.url.path.endsWith('/donors/me')
          ? FakeBackend.error(404, 'NOT_FOUND', 'El usuario no está registrado como donante')
          : request.url.path.endsWith('/users/me')
              ? FakeBackend.json(userJson(), 200)
              : FakeBackend.json(pageJson([]), 200);
      await installServices(backend, loggedIn: true);
      await pumpApp(tester, const HomeScreen());

      for (final (item, screen) in [
        ('Donor Registration', DonorRegistrationForm),
        ('Find Donors', FindDonorScreen),
        ('Blood Requests', AllRequestScreen),
        ('Profile', ProfileScreen),
      ]) {
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();
        await tester.tap(find.text(item).last);
        await tester.pumpAndSettle();

        expect(find.byType(screen), findsOneWidget, reason: item);
        expect(find.byType(Drawer), findsNothing, reason: 'el menú se cierra al navegar');

        Navigator.of(tester.element(find.byType(screen))).pop();
        await tester.pumpAndSettle();
      }
    });
  });

  group('AllRequestScreen', () {
    testWidgets('el filtro consulta el grupo elegido y "All" lo quita', (tester) async {
      backend.handler = (request) {
        final group = request.url.queryParameters['bloodGroup'];
        return FakeBackend.json(
            pageJson(group == null ? [bloodRequestJson(id: 1), bloodRequestJson(id: 2)] : [bloodRequestJson(id: 3, bloodGroup: group)]),
            200);
      };
      await installServices(backend, loggedIn: true);
      await pumpApp(tester, const AllRequestScreen());
      expect(find.byType(CustomRequestFeedItem), findsNWidgets(2));

      await tester.tap(find.text('AB+').first);
      await tester.pumpAndSettle();

      expect(backend.requests.last.url.query, contains('bloodGroup=AB%2B'));
      expect(find.byType(CustomRequestFeedItem), findsOneWidget);

      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      expect(backend.requests.last.url.queryParameters.containsKey('bloodGroup'), isFalse);
      expect(find.byType(CustomRequestFeedItem), findsNWidgets(2));
    });

    testWidgets('carga la página siguiente al llegar al final', (tester) async {
      backend.handler = (request) {
        final page = int.parse(request.url.queryParameters['page']!);
        final items = List.generate(10, (i) => bloodRequestJson(id: page * 10 + i + 1));
        return FakeBackend.json(pageJson(items, page: page, totalPages: 2), 200);
      };
      await installServices(backend, loggedIn: true);
      await pumpApp(tester, const AllRequestScreen());

      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -6000));
      await tester.pumpAndSettle();

      expect(backend.requests.map((r) => r.url.queryParameters['page']), ['0', '1']);
      expect(find.text('Paciente 20', skipOffstage: false), findsOneWidget);
    });
  });

  group('FindDonorScreen (crear solicitud)', () {
    Future<void> fillValidRequest(WidgetTester tester) async {
      await tester.enterText(fieldWithHint('3'), '3');
      await tester.enterText(fieldWithHint('+880188888888'), '+1 (809) 224-9304');
      await tester.enterText(fieldWithHint('+88019999999'), '8095550000');
      await tester.enterText(fieldWithHint('Jorge Perez'), 'María López');
      await tester.enterText(fieldWithHint('Cancer Patient'), 'Surgery');
      await tester.tap(find.text('O-'));
      await tapVisible(tester, find.text('female'));
      await tapVisible(tester, find.byIcon(Icons.calendar_month));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.enterText(fieldWithHint('Others'), 'Urgent');
    }

    testWidgets('envía los valores elegidos y abre la búsqueda de donantes del mismo grupo', (tester) async {
      backend.handler = (request) => request.url.path.endsWith('/donors')
          ? FakeBackend.json(pageJson([]), 200)
          : FakeBackend.json(bloodRequestJson(location: 'Santiago'), 201);
      await installServices(backend, loggedIn: true);
      await pumpPushed(tester, const FindDonorScreen());

      await fillValidRequest(tester);
      await tapVisible(tester, find.text('Find Donors'));

      final body = jsonDecode(backend.requestsTo('POST', '/blood-requests').single.body);
      expect(body, {
        'bloodGroup': 'O-',
        'bags': 3,
        'contactNumber': '+18092249304',
        'emergencyContact': '8095550000',
        'patientName': 'María López',
        'caseDescription': 'Surgery',
        'patientGender': 'FEMALE',
        'needBefore': toApiDate(DateTime.now()),
        'others': 'Urgent',
      });
      expect(find.byType(FindDonorScreen), findsNothing);
      expect(find.byType(DonorSearchScreen), findsOneWidget);
      expect(backend.requestsTo('GET', '/donors').single.url.queryParameters['bloodGroup'], 'O-');
      expect(find.text('Blood request published'), findsOneWidget);
    });

    testWidgets('avisa cuando la solicitud queda sin ubicación por falta de perfil', (tester) async {
      backend.handler = (request) => request.url.path.endsWith('/donors')
          ? FakeBackend.json(pageJson([]), 200)
          : FakeBackend.json(bloodRequestJson(), 201);
      await installServices(backend, loggedIn: true);
      await pumpPushed(tester, const FindDonorScreen());

      await fillValidRequest(tester);
      await tapVisible(tester, find.text('Find Donors'));

      expect(find.textContaining('Add your location in Edit Profile'), findsOneWidget);
    });

    testWidgets('valida antes de enviar y no envía datos incompletos', (tester) async {
      await installServices(backend, loggedIn: true);
      await pumpApp(tester, const FindDonorScreen());

      await tapVisible(tester, find.text('Find Donors'));
      expect(find.text('Number of bags is required'), findsOneWidget);
      await dismissSnackBar(tester);

      await tester.enterText(fieldWithHint('3'), '11');
      await tapVisible(tester, find.text('Find Donors'));
      expect(find.text('Number of bags must be between 1 and 10'), findsOneWidget);
      await dismissSnackBar(tester);

      await tester.enterText(fieldWithHint('3'), '2');
      await tester.enterText(fieldWithHint('+880188888888'), 'abc');
      await tapVisible(tester, find.text('Find Donors'));
      expect(find.text('Contact number must have between 7 and 15 digits'), findsOneWidget);

      expect(backend.requests, isEmpty);
    });

    testWidgets('muestra el error de validación del servidor', (tester) async {
      backend.handler = (_) => FakeBackend.error(400, 'VALIDATION_ERROR', 'Los datos enviados no son válidos',
          fields: [{'field': 'needBefore', 'message': 'La fecha límite no puede estar en el pasado'}]);
      await installServices(backend, loggedIn: true);
      await pumpApp(tester, const FindDonorScreen());

      await fillValidRequest(tester);
      await tapVisible(tester, find.text('Find Donors'));

      expect(find.text('La fecha límite no puede estar en el pasado'), findsOneWidget);
      expect(find.byType(FindDonorScreen), findsOneWidget);
    });
  });

  group('Calendario', () {
    testWidgets('cancelar el calendario no produce excepciones', (tester) async {
      DateTime? selected;
      usePhoneSize(tester);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: FindDonorDatePicker(onChanged: (date) => selected = date)),
      ));

      await tester.tap(find.byIcon(Icons.calendar_month));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Choose Date'), findsOneWidget);
      expect(selected, isNull);

      await tester.tap(find.byIcon(Icons.calendar_month));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(selected, isNotNull);
      expect(find.text(toPickerDate(selected!)), findsOneWidget);
    });
  });

  group('DonorRegistrationForm', () {
    const donorJson = {
      'id': 1,
      'name': 'Ana Donante',
      'contactNumber': '+18092249304',
      'bloodGroup': 'B+',
      'location': 'Santiago',
      'lastDonationDate': '2026-06-01',
    };

    testWidgets('registro nuevo: valida, envía PUT y confirma con 201', (tester) async {
      backend.handler = (request) => request.method == 'GET'
          ? FakeBackend.error(404, 'NOT_FOUND', 'El usuario no está registrado como donante')
          : FakeBackend.json(donorJson, 201);
      await installServices(backend, loggedIn: true);
      await pumpPushed(tester, const DonorRegistrationForm());

      await tapVisible(tester, find.text('Complete'));
      expect(find.text('Name is required'), findsOneWidget);
      await dismissSnackBar(tester);

      await tester.enterText(fieldWithHint('Jorge Perez'), 'Ana Donante');
      await tester.enterText(fieldWithHint('+18092249304'), '809 224 9304');
      await tester.tap(find.text('B+'));
      await tester.enterText(fieldWithHint('Santo Domingo, RD'), 'Santiago');
      await tapVisible(tester, find.byIcon(Icons.calendar_month));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Complete'));

      final body = jsonDecode(backend.requestsTo('PUT', '/donors/me').single.body);
      expect(body, {
        'name': 'Ana Donante',
        'contactNumber': '8092249304',
        'bloodGroup': 'B+',
        'location': 'Santiago',
        'lastDonationDate': toApiDate(DateTime.now()),
      });
      expect(find.text('Donor registration completed'), findsOneWidget);
    });

    testWidgets('donante existente: precarga sus datos y actualiza con 200', (tester) async {
      backend.handler = (request) => FakeBackend.json(donorJson, 200);
      await installServices(backend, loggedIn: true);
      await pumpPushed(tester, const DonorRegistrationForm());

      expect(find.text('Ana Donante'), findsOneWidget);
      expect(find.text('Santiago'), findsOneWidget);
      expect(find.text('1-6-2026'), findsOneWidget);

      await tapVisible(tester, find.text('Complete'));

      final body = jsonDecode(backend.requestsTo('PUT', '/donors/me').single.body);
      expect(body['bloodGroup'], 'B+');
      expect(body['lastDonationDate'], '2026-06-01');
      expect(find.text('Donor information updated'), findsOneWidget);
    });
  });

  group('ProfileScreen', () {
    testWidgets('muestra datos reales del usuario y de su registro de donante', (tester) async {
      backend.handler = (request) => request.url.path.endsWith('/users/me')
          ? FakeBackend.json({...userJson(), 'gender': 'FEMALE', 'phone': '+18090001111'}, 200)
          : FakeBackend.json({
              'id': 1,
              'name': 'Ana',
              'contactNumber': '+18092249304',
              'bloodGroup': 'AB-',
              'location': 'La Vega',
              'lastDonationDate': '2026-06-01',
            }, 200);
      await installServices(backend, loggedIn: true);
      await pumpApp(tester, const ProfileScreen());

      expect(find.text('Ana Perez'), findsOneWidget);
      expect(find.text('La Vega'), findsOneWidget);
      expect(find.text('Female'), findsOneWidget);
      expect(find.text('AB-'), findsOneWidget);
      expect(find.text('+18090001111'), findsOneWidget);
      expect(find.text('Jorge Perez'), findsNothing);
    });

    testWidgets('usuario sin registro de donante muestra guiones', (tester) async {
      backend.handler = (request) => request.url.path.endsWith('/users/me')
          ? FakeBackend.json(userJson(), 200)
          : FakeBackend.error(404, 'NOT_FOUND', 'El usuario no está registrado como donante');
      await installServices(backend, loggedIn: true);
      await pumpApp(tester, const ProfileScreen());

      expect(find.text('Ana Perez'), findsOneWidget);
      expect(find.text('—'), findsNWidgets(4));
    });
  });
}
