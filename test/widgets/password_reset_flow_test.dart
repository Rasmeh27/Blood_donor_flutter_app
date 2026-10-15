import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_laboratorio_intec/src/screens/views/auth/forgot_password_screen.dart';
import 'package:proyecto_laboratorio_intec/src/screens/views/auth/login_screen.dart';
import 'package:proyecto_laboratorio_intec/src/screens/views/auth/otp_recovery_screen.dart';
import 'package:proyecto_laboratorio_intec/src/screens/views/auth/recovery_screen.dart';

import '../support/fake_backend.dart';
import '../support/widget_helpers.dart';

void main() {
  late FakeBackend backend;

  setUp(() {
    backend = FakeBackend((request) {
      if (request.url.path.endsWith('/forgot')) {
        return FakeBackend.json({'message': 'Si el correo está registrado, recibirás un código'}, 202);
      }
      return FakeBackend.json({}, 204);
    });
  });

  Future<void> enterOtp(WidgetTester tester, String code) async {
    final fields = find.byType(TextField);
    for (var i = 0; i < code.length; i++) {
      await tester.enterText(fields.at(i), code[i]);
      await tester.pump();
    }
  }

  testWidgets('Forgot Password envía el correo y abre la verificación del código', (tester) async {
    await installServices(backend);
    await pumpApp(tester, const ForgotPasswordScreen());

    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'ana@mail.com');
    await tester.tap(find.text('SEND'));
    await tester.pumpAndSettle();

    expect(find.byType(OtpRecoveryScreen), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(OtpRecoveryScreen.codeLength));
    expect(jsonDecode(backend.requests.single.body), {'email': 'ana@mail.com'});
    expect(find.text('If the email is registered, you will receive a verification code'), findsOneWidget);
  });

  testWidgets('"Verify Using Number Here" exige un correo válido', (tester) async {
    await installServices(backend);
    await pumpApp(tester, const ForgotPasswordScreen());

    await tester.tap(find.text('Verify Using Number Here'));
    await tester.pumpAndSettle();
    expect(find.text('email is required'), findsOneWidget);
    expect(find.byType(OtpRecoveryScreen), findsNothing);

    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'ana@mail.com');
    await tester.tap(find.text('Verify Using Number Here'));
    await tester.pumpAndSettle();
    expect(find.byType(OtpRecoveryScreen), findsOneWidget);
    expect(backend.requests, isEmpty);
  });

  testWidgets('el código verificado pasa a Recovery con el código precargado', (tester) async {
    await installServices(backend);
    await pumpApp(tester, const OtpRecoveryScreen(email: 'ana@mail.com'));

    await enterOtp(tester, '482913');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Verify'));
    await tester.pumpAndSettle();

    expect(jsonDecode(backend.requests.single.body), {'email': 'ana@mail.com', 'code': '482913'});
    expect(find.byType(RecoveryScreen), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '482913'), findsOneWidget);
  });

  testWidgets('código incorrecto muestra el error y no avanza', (tester) async {
    backend.handler = (_) => FakeBackend.error(400, 'INVALID_RESET_CODE', 'El código es inválido o ha expirado');
    await installServices(backend);
    await pumpApp(tester, const OtpRecoveryScreen(email: 'ana@mail.com'));

    await enterOtp(tester, '000000');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Verify'));
    await tester.pumpAndSettle();

    expect(find.text('El código es inválido o ha expirado'), findsOneWidget);
    expect(find.byType(RecoveryScreen), findsNothing);
  });

  testWidgets('código incompleto no se envía', (tester) async {
    await installServices(backend);
    await pumpApp(tester, const OtpRecoveryScreen(email: 'ana@mail.com'));

    await enterOtp(tester, '123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Verify'));
    await tester.pumpAndSettle();

    expect(find.text('Enter the 6-digit code sent to your email'), findsOneWidget);
    expect(backend.requests, isEmpty);
  });

  testWidgets('Recovery valida la nueva contraseña, la guarda y vuelve a Login', (tester) async {
    await installServices(backend);
    await pumpApp(tester, const RecoveryScreen(email: 'ana@mail.com', code: '482913'));

    await tester.enterText(find.widgetWithText(TextFormField, 'New Password'), 'Nueva#2026');
    await tester.enterText(find.widgetWithText(TextFormField, 'Confirm Password'), 'Distinta#2026');
    await tester.tap(find.text('RESET PASSWORD'));
    await tester.pumpAndSettle();
    expect(find.text('passwords do not match'), findsOneWidget);
    expect(backend.requests, isEmpty);

    await tester.enterText(find.widgetWithText(TextFormField, 'Confirm Password'), 'Nueva#2026');
    await tester.tap(find.text('RESET PASSWORD'));
    await tester.pumpAndSettle();

    expect(jsonDecode(backend.requests.single.body),
        {'email': 'ana@mail.com', 'code': '482913', 'newPassword': 'Nueva#2026'});
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Password updated. Log in with your new password.'), findsOneWidget);
  });
}
