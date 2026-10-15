class ApiConfig {
  // 10.0.2.2 es el localhost del equipo visto desde el emulador de Android.
  // Se puede cambiar sin tocar código: flutter run --dart-define=API_BASE_URL=http://<ip>:8080/api/v1
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080/api/v1',
  );

  static const requestTimeout = Duration(seconds: 15);
}
