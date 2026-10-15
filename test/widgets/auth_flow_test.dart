import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:proyecto_laboratorio_intec/main.dart';
import 'package:proyecto_laboratorio_intec/src/screens/views/auth/login_screen.dart';
import 'package:proyecto_laboratorio_intec/src/screens/views/auth/register_screen.dart';
import 'package:proyecto_laboratorio_intec/src/screens/views/home/screens/home_screen.dart';
import 'package:proyecto_laboratorio_intec/src/screens/views/onboarding/onboarding_screen.dart';

import '../support/fake_backend.dart';
import '../support/widget_helpers.dart';

void main() {
  late FakeBackend backend;

  http.Response loginOk() => FakeBackend.json({
        'tokenType': 'Bearer',
        'accessToken': 'jwt.token.value',
        'expiresAt': DateTime.now().add(const Duration(hours: 1)).toUtc().toIso8601String(),
        'user': userJson(),
      }, 200);

  setUp(() {
    backend = FakeBackend((request) {
      if (request.url.path.endsWith('/blood-requests')) return FakeBackend.json(pageJson([]), 200);
      return FakeBackend.json({}, 404);
    });
  });

  Future<void> fillLogin(WidgetTester tester, String email, String password) async {
    await tester.enterText(find.widgetWithText(TextFormField, 'Enter your Email'), email);
    await tester.enterText(find.widgetWithText(TextFormField, 'Enter your Password'), password);
  }

  group('Login', () {
    testWidgets('valida los campos sin llamar al servidor', (tester) async {
      await installServices(backend);
      await pumpApp(tester, const LoginScreen());

      await tester.tap(find.text('LOGIN'));
      await tester.pumpAndSettle();

      expect(find.text('email is required'), findsOneWidget);
      expect(find.text('password is required'), findsOneWidget);
      expect(backend.requests, isEmpty);
    });

    testWidgets('credenciales correctas guardan la sesión y abren Home', (tester) async {
      final services = await installServices(backend);
      backend.handler = (request) => request.url.path.endsWith('/auth/login')
          ? loginOk()
          : FakeBackend.json(pageJson([]), 200);
      await pumpApp(tester, const LoginScreen());

      await fillLogin(tester, 'ana@mail.com', 'Secreta#123');
      await tester.tap(find.text('LOGIN'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(services.session.validToken, 'jwt.token.value');
      final body = jsonDecode(backend.requestsTo('POST', '/auth/login').single.body);
      expect(body, {'email': 'ana@mail.com', 'password': 'Secreta#123'});
    });

    testWidgets('contraseña incorrecta muestra el mensaje y permanece en Login', (tester) async {
      await installServices(backend);
      backend.handler = (_) => FakeBackend.error(401, 'INVALID_CREDENTIALS', 'Correo o contraseña incorrectos');
      await pumpApp(tester, const LoginScreen());

      await fillLogin(tester, 'ana@mail.com', 'Mala#12345');
      await tester.tap(find.text('LOGIN'));
      await tester.pumpAndSettle();

      expect(find.text('Correo o contraseña incorrectos'), findsOneWidget);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('sin conexión muestra un mensaje comprensible', (tester) async {
      await installServices(backend);
      backend.handler = (_) => throw http.ClientException('Connection refused');
      await pumpApp(tester, const LoginScreen());

      await fillLogin(tester, 'ana@mail.com', 'Secreta#123');
      await tester.tap(find.text('LOGIN'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Could not connect to the server'), findsOneWidget);
    });

    testWidgets('toques repetidos envían una sola petición', (tester) async {
      final pending = Completer<http.Response>();
      await installServices(backend);
      backend.handler = (_) => pending.future;
      await pumpApp(tester, const LoginScreen());

      await fillLogin(tester, 'ana@mail.com', 'Secreta#123');
      await tester.tap(find.text('LOGIN'));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 150));

      expect(backend.requests.length, 1);
      pending.complete(FakeBackend.error(401, 'INVALID_CREDENTIALS', 'Correo o contraseña incorrectos'));
      await tester.pumpAndSettle();
    });
  });

  group('Register', () {
    Future<void> fillRegister(WidgetTester tester, {required String confirm}) async {
      await tester.enterText(find.widgetWithText(TextFormField, 'Enter your name'), 'Ana Perez');
      await tester.enterText(find.widgetWithText(TextFormField, 'Enter your email'), 'ana@mail.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Enter your password'), 'Secreta#123');
      await tester.enterText(find.widgetWithText(TextFormField, 'Confirm your password'), confirm);
    }

    testWidgets('rechaza contraseñas que no coinciden', (tester) async {
      await installServices(backend);
      await pumpApp(tester, const RegisterScreen());

      await fillRegister(tester, confirm: 'Distinta#123');
      await tester.ensureVisible(find.text('REGISTER'));
      await tester.tap(find.text('REGISTER'));
      await tester.pumpAndSettle();

      expect(find.text('passwords do not match'), findsOneWidget);
      expect(backend.requests, isEmpty);
    });

    testWidgets('correo duplicado muestra el mensaje del servidor', (tester) async {
      await installServices(backend);
      backend.handler = (_) => FakeBackend.error(409, 'CONFLICT', 'El correo ya esta registrado');
      await pumpApp(tester, const RegisterScreen());

      await fillRegister(tester, confirm: 'Secreta#123');
      await tester.ensureVisible(find.text('REGISTER'));
      await tester.tap(find.text('REGISTER'));
      await tester.pumpAndSettle();

      expect(find.text('El correo ya esta registrado'), findsOneWidget);
    });

    testWidgets('registro exitoso vuelve a Login sin modificar la contraseña', (tester) async {
      await installServices(backend);
      backend.handler = (_) => FakeBackend.json(userJson(), 201);
      await pumpApp(tester, const LoginScreen());

      await tester.tap(find.text('Register Here'));
      await tester.pumpAndSettle();
      await fillRegister(tester, confirm: 'Secreta#123');
      await tester.ensureVisible(find.text('REGISTER'));
      await tester.tap(find.text('REGISTER'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(RegisterScreen), findsNothing);
      expect(find.text('Account successfully created!'), findsOneWidget);
      final body = jsonDecode(backend.requests.single.body);
      expect(body, {'name': 'Ana Perez', 'email': 'ana@mail.com', 'password': 'Secreta#123'});
    });

    testWidgets('Show Password muestra el texto de ambas contraseñas', (tester) async {
      await installServices(backend);
      await pumpApp(tester, const RegisterScreen());

      bool obscured(String label) =>
          tester.widget<TextField>(find.descendant(
              of: find.widgetWithText(TextFormField, label), matching: find.byType(TextField))).obscureText;

      expect(obscured('Enter your password'), isTrue);
      await tester.ensureVisible(find.byIcon(Icons.remove_red_eye));
      await tester.tap(find.byIcon(Icons.remove_red_eye));
      await tester.pump();
      expect(obscured('Enter your password'), isFalse);
      expect(obscured('Confirm your password'), isFalse);
    });
  });

  group('Sesión', () {
    testWidgets('al abrir la app con sesión vigente, Splash va directo a Home', (tester) async {
      await installServices(backend, loggedIn: true);
      await pumpPhone(tester, const ValideiApp());

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('sin sesión, Splash va a Onboarding', (tester) async {
      await installServices(backend);
      await pumpPhone(tester, const ValideiApp());

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsOneWidget);
    });

    testWidgets('Logout del menú elimina la sesión y abre Login', (tester) async {
      final services = await installServices(backend, loggedIn: true);
      await pumpApp(tester, const HomeScreen());

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      expect(find.text('Ana Perez'), findsOneWidget);

      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(services.session.isActive, isFalse);
    });

    testWidgets('un 401 del servidor redirige a Login desde cualquier pantalla', (tester) async {
      final services = await installServices(backend, loggedIn: true);
      services.apiClient.onSessionExpired = () => appNavigatorKey.currentState
          ?.pushNamedAndRemoveUntil(LoginScreen.pageRoute, (_) => false);
      backend.handler = (_) => FakeBackend.error(401, 'UNAUTHORIZED', 'El token es inválido o ha expirado');

      await pumpPhone(tester, const ValideiApp());
      appNavigatorKey.currentState!.pushReplacementNamed(HomeScreen.pageRoute);
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(services.session.isActive, isFalse);
    });
  });
}
