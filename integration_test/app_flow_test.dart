// Prueba integral en el emulador contra el backend real (Spring Boot + MySQL + Mailpit).
// Requisitos: docker compose up -d (MySQL y Mailpit) y el backend en http://10.0.2.2:8080.
//   flutter test integration_test/app_flow_test.dart -d emulator-5554
// No usa respuestas simuladas: crea datos reales con correos únicos por ejecución.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:proyecto_laboratorio_intec/main.dart' as app;
import 'package:proyecto_laboratorio_intec/src/screens/views/all_request_details/screens/request_details_screen.dart';
import 'package:proyecto_laboratorio_intec/src/screens/views/donor_search/screens/donor_search_screen.dart';
import 'package:proyecto_laboratorio_intec/src/screens/views/donor_search/widgets/donor_result_item.dart';
import 'package:proyecto_laboratorio_intec/src/screens/views/home/widgets/request_feed_item.dart';
import 'package:proyecto_laboratorio_intec/src/screens/views/profile/screens/profile_screen.dart';
import 'package:proyecto_laboratorio_intec/src/services/app_services.dart';

const api = 'http://10.0.2.2:8080/api/v1';
const mailpit = 'http://10.0.2.2:8025/api/v1';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final runId = DateTime.now().millisecondsSinceEpoch;
  final email = 'it.$runId@validei.test';
  const password = 'Integracion#2026';
  const newPassword = 'Recuperada#2026';
  final patientName = 'Paciente IT $runId';
  final helperDonorName = 'Donante IT $runId';

  Future<void> pumpUntil(WidgetTester tester, Finder finder, {Duration timeout = const Duration(seconds: 20)}) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 200));
      if (finder.evaluate().isNotEmpty) return;
    }
    fail('No apareció: $finder');
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pump();
  }

  Future<void> typeInto(WidgetTester tester, Finder field, String text) async {
    await tester.ensureVisible(field);
    await tester.enterText(field, text);
    await tester.pump();
  }

  Future<void> goBack(WidgetTester tester) async {
    // Espera a que termine cualquier transición para no tocar la pantalla que está saliendo
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_outlined).last);
    await tester.pumpAndSettle();
  }

  Finder field(String text) => find.widgetWithText(TextField, text);

  Future<void> chooseTodayInCalendar(WidgetTester tester) async {
    await tapVisible(tester, find.byIcon(Icons.calendar_month));
    await pumpUntil(tester, find.text('OK'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  Future<void> login(WidgetTester tester, String userPassword) async {
    await typeInto(tester, find.widgetWithText(TextFormField, 'Enter your Email'), email);
    await typeInto(tester, find.widgetWithText(TextFormField, 'Enter your Password'), userPassword);
    await tapVisible(tester, find.text('LOGIN'));
    await pumpUntil(tester, find.text('Request Feed'));
  }

  Future<void> openProfile(WidgetTester tester) async {
    await tester.tap(find.descendant(of: find.byType(AppBar), matching: find.byType(Image)).first);
    await pumpUntil(tester, find.byType(ProfileScreen));
    await tester.pumpAndSettle();
  }

  // Donante de otro usuario, creado por la API, que autorizó aparecer en la búsqueda
  Future<void> createConsentingDonor() async {
    final helperEmail = 'it.helper.$runId@validei.test';
    final headers = {'Content-Type': 'application/json'};
    await http.post(Uri.parse('$api/auth/register'), headers: headers,
        body: jsonEncode({'name': helperDonorName, 'email': helperEmail, 'password': password}));
    final loginResponse = await http.post(Uri.parse('$api/auth/login'), headers: headers,
        body: jsonEncode({'email': helperEmail, 'password': password}));
    final token = jsonDecode(loginResponse.body)['accessToken'] as String;
    final auth = {...headers, 'Authorization': 'Bearer $token'};
    await http.put(Uri.parse('$api/donors/me'), headers: auth, body: jsonEncode({
      'name': helperDonorName,
      'contactNumber': '+18090000000',
      'bloodGroup': 'AB+',
      'location': 'La Vega',
      'lastDonationDate': '2026-05-01',
    }));
    final consent = await http.patch(Uri.parse('$api/donors/me/visibility'), headers: auth,
        body: jsonEncode({'visibleInSearch': true}));
    expect(consent.statusCode, 200);
  }

  // Lee el código real del correo recibido en Mailpit
  Future<String> readResetCodeFromMailpit() async {
    for (var attempt = 0; attempt < 20; attempt++) {
      final search = await http.get(Uri.parse('$mailpit/search?query=${Uri.encodeQueryComponent('to:"$email"')}'));
      final messages = (jsonDecode(search.body)['messages'] as List<dynamic>);
      if (messages.isNotEmpty) {
        final id = messages.first['ID'];
        final message = jsonDecode((await http.get(Uri.parse('$mailpit/message/$id'))).body);
        return RegExp(r'es: (\d{6})').firstMatch(message['Text'] as String)!.group(1)!;
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    fail('No llegó el correo de recuperación a Mailpit');
  }

  testWidgets('flujo integral: registro, perfil, donante, búsqueda, solicitudes, recuperación y logout',
      (tester) async {
    await createConsentingDonor();
    await AppServices.instance.session.restore();
    await AppServices.instance.session.clear();

    app.main();
    await pumpUntil(tester, find.text('Skip'));

    // 1. Registro e inicio de sesión
    await tester.tap(find.text('Skip'));
    await pumpUntil(tester, find.text('Register Here'));
    await tapVisible(tester, find.text('Register Here'));
    await pumpUntil(tester, find.text('Create Your Account!'));
    await typeInto(tester, find.widgetWithText(TextFormField, 'Enter your name'), 'Usuario Integración');
    await typeInto(tester, find.widgetWithText(TextFormField, 'Enter your email'), email);
    await typeInto(tester, find.widgetWithText(TextFormField, 'Enter your password'), password);
    await typeInto(tester, find.widgetWithText(TextFormField, 'Confirm your password'), password);
    await tapVisible(tester, find.text('REGISTER'));
    await pumpUntil(tester, find.text('Account successfully created!'));
    await login(tester, password);

    // 2. Editar perfil: ubicación y género, y comprobarlo en Profile
    await openProfile(tester);
    await tapVisible(tester, find.text('Edit Profile'));
    await pumpUntil(tester, find.text('Save'));
    await typeInto(tester, field('Santo Domingo, RD'), 'Santiago, RD');
    await tapVisible(tester, find.text('female'));
    await tapVisible(tester, find.text('Save'));
    await pumpUntil(tester, find.text('Santiago, RD'));
    expect(find.text('Female'), findsOneWidget);
    await goBack(tester);

    // 3. Registrar los datos de donante
    await tapVisible(tester, find.text('I want to donate'));
    await pumpUntil(tester, find.text('Donor Registration Form'));
    await typeInto(tester, field('Jorge Perez'), 'Usuario Integración');
    await typeInto(tester, field('+18092249304'), '+18092249304');
    await tapVisible(tester, find.text('O-'));
    await typeInto(tester, field('Santo Domingo, RD'), 'Santiago, RD');
    await chooseTodayInCalendar(tester);
    await tapVisible(tester, find.text('Complete'));
    await pumpUntil(tester, find.text('Donor registration completed'));

    // 4. Consentimiento para aparecer en la búsqueda (Edit Profile)
    await openProfile(tester);
    await tapVisible(tester, find.text('Edit Profile'));
    await pumpUntil(tester, find.byType(Switch));
    await tapVisible(tester, find.byType(Switch));
    await tapVisible(tester, find.text('Save'));
    await pumpUntil(tester, find.text('Profile updated'));
    await goBack(tester);

    // 5. Publicar una solicitud y ver la búsqueda real de donantes del mismo grupo
    await tapVisible(tester, find.text('Find a donor'));
    await pumpUntil(tester, find.text('Patient Details'));
    await tapVisible(tester, find.text('AB+'));
    await typeInto(tester, field('3'), '2');
    await typeInto(tester, field('+880188888888'), '+18092249304');
    await typeInto(tester, field('+88019999999'), '+18095550000');
    await typeInto(tester, field('Jorge Perez'), patientName);
    await typeInto(tester, field('Cancer Patient'), 'Accident');
    await chooseTodayInCalendar(tester);
    await tapVisible(tester, find.text('Find Donors'));
    await pumpUntil(tester, find.byType(DonorSearchScreen));
    await pumpUntil(tester, find.text(helperDonorName));
    expect(find.byType(DonorResultItem), findsWidgets);
    expect(find.text('+18090000000'), findsNothing); // la búsqueda no expone teléfonos
    await goBack(tester);

    // 6. La solicitud aparece en el feed con la ubicación del perfil y se abre su detalle
    await pumpUntil(tester, find.text(patientName));
    final card = find.ancestor(of: find.text(patientName), matching: find.byType(CustomRequestFeedItem));
    expect(find.descendant(of: card, matching: find.text('Santiago, RD')), findsOneWidget);
    await tapVisible(tester, find.descendant(of: card, matching: find.text('Details')));
    await pumpUntil(tester, find.text('2 Bags'));
    expect(find.descendant(of: find.byType(RequestDetailsScreen), matching: find.text('Santiago, RD')),
        findsOneWidget);
    await goBack(tester);

    // 7. Cerrar sesión
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Logout'));
    await pumpUntil(tester, find.text('Welcome Back!'));
    expect(AppServices.instance.session.isActive, isFalse);

    // 8. Recuperar la contraseña con el código recibido por correo
    await tapVisible(tester, find.text('Forgot Your Password?'));
    await pumpUntil(tester, find.text('Forgot Password'));
    await typeInto(tester, find.widgetWithText(TextFormField, 'Email'), email);
    await tapVisible(tester, find.text('SEND'));
    await pumpUntil(tester, find.widgetWithText(ElevatedButton, 'Verify'));
    final code = await readResetCodeFromMailpit();
    final otpFields = find.byType(TextField);
    for (var i = 0; i < code.length; i++) {
      await tester.enterText(otpFields.at(i), code[i]);
      await tester.pump();
    }
    await tapVisible(tester, find.widgetWithText(ElevatedButton, 'Verify'));
    await pumpUntil(tester, find.text('Recover your Account'));
    await typeInto(tester, find.widgetWithText(TextFormField, 'New Password'), newPassword);
    await typeInto(tester, find.widgetWithText(TextFormField, 'Confirm Password'), newPassword);
    await tapVisible(tester, find.text('RESET PASSWORD'));
    await pumpUntil(tester, find.text('Welcome Back!'));

    // 9. Iniciar sesión con la nueva contraseña
    await login(tester, newPassword);
    expect(AppServices.instance.session.isActive, isTrue);
    debugPrint('IT_EMAIL=$email IT_PATIENT=$patientName');
  });
}
