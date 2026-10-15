// Smoke test mínimo: la app arranca con el flujo original (Splash) y no requiere Firebase.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:proyecto_laboratorio_intec/main.dart';
import 'package:proyecto_laboratorio_intec/src/screens/views/onboarding/splash_screen.dart';

import 'support/fake_backend.dart';
import 'support/widget_helpers.dart';

void main() {
  testWidgets('ValideiApp arranca y muestra un MaterialApp', (WidgetTester tester) async {
    await installServices(FakeBackend());
    await pumpPhone(tester, const ValideiApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(SplashScreen), findsOneWidget);

    // Deja que termine el temporizador del Splash
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });
}
