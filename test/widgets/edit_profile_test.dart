import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:proyecto_laboratorio_intec/src/screens/views/edit_profile/screens/edit_profile_screen.dart';
import 'package:proyecto_laboratorio_intec/src/screens/views/profile/screens/profile_screen.dart';

import '../support/fake_backend.dart';
import '../support/widget_helpers.dart';

Finder fieldWithText(String text) => find.widgetWithText(TextField, text);

Future<void> tapSave(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Save'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Save'));
  await tester.pump();
}

void main() {
  late FakeBackend backend;
  late Map<String, dynamic> storedUser;

  setUp(() {
    storedUser = {...userJson(location: 'Santiago'), 'phone': '+18090001111', 'gender': 'FEMALE'};
    backend = FakeBackend((request) {
      if (request.method == 'PATCH') {
        final changes = jsonDecode(request.body) as Map<String, dynamic>;
        storedUser = {...storedUser, ...changes};
        return FakeBackend.json(storedUser, 200);
      }
      if (request.url.path.endsWith('/donors/me')) {
        return FakeBackend.error(404, 'NOT_FOUND', 'El usuario no está registrado como donante');
      }
      return FakeBackend.json(storedUser, 200);
    });
  });

  testWidgets('precarga los datos actuales del usuario', (tester) async {
    await installServices(backend, loggedIn: true);
    await pumpApp(tester, const EditProfileScreen());

    expect(fieldWithText('Ana Perez'), findsOneWidget);
    expect(fieldWithText('+18090001111'), findsOneWidget);
    expect(fieldWithText('Santiago'), findsOneWidget);
    expect(backend.requestsTo('GET', '/users/me'), hasLength(1));
  });

  testWidgets('guarda solo los campos admitidos y actualiza Profile al volver', (tester) async {
    await installServices(backend, loggedIn: true);
    await pumpApp(tester, const ProfileScreen());
    expect(find.text('Santiago'), findsOneWidget);

    await tester.tap(find.text('Edit Profile'));
    await tester.pumpAndSettle();
    expect(find.byType(EditProfileScreen), findsOneWidget);

    await tester.enterText(fieldWithText('Ana Perez'), 'Ana María');
    await tester.enterText(fieldWithText('Santiago'), 'La Romana');
    await tester.enterText(fieldWithText('+18090001111'), '809 555 1234');
    await tester.tap(find.text('male'));
    await tapSave(tester);
    await tester.pumpAndSettle();

    final body = jsonDecode(backend.requestsTo('PATCH', '/users/me').single.body);
    expect(body, {'name': 'Ana María', 'phone': '8095551234', 'gender': 'MALE', 'location': 'La Romana'});
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.text('Ana María'), findsOneWidget);
    expect(find.text('La Romana'), findsOneWidget);
    expect(find.text('Male'), findsOneWidget);
    expect(find.text('Profile updated'), findsOneWidget);
  });

  testWidgets('valida antes de enviar', (tester) async {
    await installServices(backend, loggedIn: true);
    await pumpApp(tester, const EditProfileScreen());

    await tester.enterText(fieldWithText('Ana Perez'), '   ');
    await tapSave(tester);
    await tester.pumpAndSettle();
    expect(find.text('Name is required'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Ana');
    await tester.enterText(fieldWithText('+18090001111'), 'abc');
    await tapSave(tester);
    await tester.pumpAndSettle();
    expect(find.text('Mobile number must have between 7 and 15 digits'), findsOneWidget);

    expect(backend.requestsTo('PATCH', '/users/me'), isEmpty);
  });

  testWidgets('muestra el error del backend y permanece en la pantalla', (tester) async {
    await installServices(backend, loggedIn: true);
    final getHandler = backend.handler;
    backend.handler = (request) => request.method == 'PATCH'
        ? FakeBackend.error(400, 'VALIDATION_ERROR', 'Los datos enviados no son válidos',
            fields: [{'field': 'phone', 'message': 'El teléfono debe tener entre 7 y 15 dígitos'}])
        : getHandler(request);
    await pumpApp(tester, const EditProfileScreen());

    await tapSave(tester);
    await tester.pumpAndSettle();

    expect(find.text('El teléfono debe tener entre 7 y 15 dígitos'), findsOneWidget);
    expect(find.byType(EditProfileScreen), findsOneWidget);
  });

  testWidgets('toques repetidos en Save envían un solo PATCH', (tester) async {
    final pending = Completer<http.Response>();
    await installServices(backend, loggedIn: true);
    final getHandler = backend.handler;
    backend.handler = (request) => request.method == 'PATCH' ? pending.future : getHandler(request);
    await pumpPushed(tester, const EditProfileScreen());

    await tapSave(tester);
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(backend.requestsTo('PATCH', '/users/me'), hasLength(1));
    pending.complete(FakeBackend.json(storedUser, 200));
    await tester.pumpAndSettle();
  });

  testWidgets('no envía el género si el usuario no lo ha elegido nunca', (tester) async {
    storedUser = userJson();
    await installServices(backend, loggedIn: true);
    await pumpPushed(tester, const EditProfileScreen());

    await tapSave(tester);
    await tester.pumpAndSettle();

    final body = jsonDecode(backend.requestsTo('PATCH', '/users/me').single.body) as Map<String, dynamic>;
    expect(body.containsKey('gender'), isFalse);
    expect(body, {'name': 'Ana Perez'});
  });
}
