import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_laboratorio_intec/main.dart';
import 'package:proyecto_laboratorio_intec/src/general/config/colors.dart';

/// Pantalla de un Pixel 8 (1080x2400 px, densidad 2.625).
void usePhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
}

Future<void> pumpPhone(WidgetTester tester, Widget app) async {
  usePhoneSize(tester);
  await tester.pumpWidget(app);
}

/// Abre [screen] con las mismas rutas y tema de la app real.
Future<void> pumpApp(WidgetTester tester, Widget screen, {Object? arguments}) async {
  usePhoneSize(tester);
  await tester.pumpWidget(MaterialApp(
    navigatorKey: appNavigatorKey,
    scaffoldMessengerKey: appMessengerKey,
    theme: ThemeData(
      primaryColor: AppColor.redColor,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColor.redColor),
    ),
    routes: appRoutes,
    onGenerateInitialRoutes: (_) => [
      MaterialPageRoute(
        settings: RouteSettings(name: '/test', arguments: arguments),
        builder: (_) => screen,
      ),
    ],
  ));
  await tester.pumpAndSettle();
}

/// Abre [screen] encima de una pantalla base, como ocurre en la app (por ejemplo desde Home),
/// para comprobar el regreso con Navigator.pop y los mensajes mostrados al volver.
Future<void> pumpPushed(WidgetTester tester, Widget screen) async {
  await pumpApp(tester, const Scaffold(body: Text('Pantalla anterior')));
  appNavigatorKey.currentState!.push(MaterialPageRoute(builder: (_) => screen));
  await tester.pumpAndSettle();
}
