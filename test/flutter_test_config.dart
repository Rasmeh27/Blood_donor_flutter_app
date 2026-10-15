import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Se ejecuta antes de cada archivo de test. Carga las fuentes reales (Roboto del SDK y
/// Poppins de assets/fonts) para que el layout de las pruebas mida igual que en el
/// dispositivo; la fuente de prueba por defecto es más ancha y provoca desbordamientos falsos.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null) {
    final materialFonts = '$flutterRoot/bin/cache/artifacts/material_fonts';
    await _loadFont('Roboto', [
      '$materialFonts/roboto-regular.ttf',
      '$materialFonts/roboto-medium.ttf',
      '$materialFonts/roboto-bold.ttf',
    ]);
    await _loadFont('MaterialIcons', ['$materialFonts/materialicons-regular.otf']);
  }

  await _loadFont('Poppins', [
    'assets/fonts/Poppins-Regular.ttf',
    'assets/fonts/Poppins-SemiBold.ttf',
    'assets/fonts/Poppins-Bold.ttf',
    'assets/fonts/Poppins-Black.ttf',
  ]);
  await _loadFont('PoppinsBold', ['assets/fonts/Poppins-Bold.ttf']);

  await testMain();
}

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    final file = File(path);
    if (file.existsSync()) {
      loader.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
    }
  }
  await loader.load();
}
