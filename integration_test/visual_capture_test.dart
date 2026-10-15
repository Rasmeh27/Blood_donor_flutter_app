// Recorrido auxiliar para documentar las pantallas añadidas (capturas del reporte final).
// Imprime "SHOT:<nombre>" y espera para que un script externo ejecute `adb exec-out screencap`.
// Requiere el backend real; inicia sesión con un usuario nuevo y datos reales.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:proyecto_laboratorio_intec/main.dart' as app;
import 'package:proyecto_laboratorio_intec/src/screens/views/auth/forgot_password_screen.dart';
import 'package:proyecto_laboratorio_intec/src/screens/views/auth/otp_recovery_screen.dart';
import 'package:proyecto_laboratorio_intec/src/screens/views/auth/recovery_screen.dart';
import 'package:proyecto_laboratorio_intec/src/screens/views/donor_search/screens/donor_search_screen.dart';
import 'package:proyecto_laboratorio_intec/src/screens/views/edit_profile/screens/edit_profile_screen.dart';
import 'package:proyecto_laboratorio_intec/src/services/app_services.dart';

const api = 'http://10.0.2.2:8080/api/v1';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final runId = DateTime.now().millisecondsSinceEpoch;
  final email = 'visual.$runId@validei.test';
  const password = 'Visual#2026';

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    debugPrint('SHOT:$name');
    await Future<void>.delayed(const Duration(seconds: 4));
  }

  Future<void> open(WidgetTester tester, Route<void> route) async {
    app.appNavigatorKey.currentState!.push(route);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  }

  testWidgets('capturas de las pantallas nuevas', (tester) async {
    final headers = {'Content-Type': 'application/json'};
    await http.post(Uri.parse('$api/auth/register'), headers: headers,
        body: jsonEncode({'name': 'Usuario Visual', 'email': email, 'password': password}));
    await AppServices.instance.session.restore();
    await AppServices.instance.session.clear();
    await AppServices.instance.auth.login(email: email, password: password);
    await AppServices.instance.users.updateCurrentUser(location: 'Santiago, RD');
    await AppServices.instance.donors.saveMyDonor(
      name: 'Usuario Visual',
      contactNumber: '+18092249304',
      bloodGroup: 'AB+',
      location: 'Santiago, RD',
      lastDonationDate: DateTime(2026, 6, 1),
    );

    app.main();
    // Espera a que Splash reemplace su ruta por Home antes de abrir otras pantallas
    final end = DateTime.now().add(const Duration(seconds: 20));
    while (find.text('Request Feed').evaluate().isEmpty && DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.pumpAndSettle();

    await open(tester, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
    await shot(tester, 'edit_profile');
    await tester.drag(find.byType(SingleChildScrollView).last, const Offset(0, -600));
    await shot(tester, 'edit_profile_bottom');

    await open(tester, MaterialPageRoute(
      settings: const RouteSettings(name: DonorSearchScreen.pageRoute, arguments: 'AB+'),
      builder: (_) => const DonorSearchScreen(),
    ));
    await shot(tester, 'donor_search');

    await open(tester, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));
    await shot(tester, 'forgot_password');

    await open(tester, MaterialPageRoute(builder: (_) => OtpRecoveryScreen(email: email)));
    await shot(tester, 'otp');

    await open(tester, MaterialPageRoute(builder: (_) => RecoveryScreen(email: email, code: '123456')));
    await shot(tester, 'recovery');
  });
}
