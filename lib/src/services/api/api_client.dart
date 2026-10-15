import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../general/config/api_config.dart';
import '../session_service.dart';
import 'api_exception.dart';

typedef ApiResponse = ({int statusCode, Map<String, dynamic> body});

/// Único punto de acceso HTTP a la API de Spring Boot: JSON, Bearer JWT, timeouts
/// y traducción de errores a [ApiException].
class ApiClient {
  final http.Client _httpClient;
  final SessionService _session;
  final String _baseUrl;
  final Duration _timeout;

  /// Se invoca cuando el servidor rechaza el token (401) o este venció localmente.
  void Function()? onSessionExpired;

  ApiClient({
    required http.Client httpClient,
    required SessionService session,
    String baseUrl = ApiConfig.baseUrl,
    Duration timeout = ApiConfig.requestTimeout,
    this.onSessionExpired,
  })  : _httpClient = httpClient,
        _session = session,
        _baseUrl = baseUrl,
        _timeout = timeout;

  Future<ApiResponse> get(String path, {Map<String, String>? query, bool authenticated = true}) =>
      _send('GET', path, query: query, authenticated: authenticated);

  Future<ApiResponse> post(String path, {Object? body, bool authenticated = true}) =>
      _send('POST', path, body: body, authenticated: authenticated);

  Future<ApiResponse> put(String path, {Object? body}) => _send('PUT', path, body: body);

  Future<ApiResponse> patch(String path, {Object? body}) => _send('PATCH', path, body: body);

  /// Sube un archivo como multipart/form-data (p. ej. la foto del donante).
  Future<ApiResponse> putMultipart(
    String path, {
    required String field,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final request = http.MultipartRequest('PUT', Uri.parse('$_baseUrl$path'))
      ..files.add(http.MultipartFile.fromBytes(field, bytes, filename: fileName));
    final response = await _sendAuthorized(request, authenticated: true);
    return _jsonResult(response, authenticated: true);
  }

  /// Descarga un contenido binario (p. ej. una imagen).
  Future<Uint8List> getBytes(String path) async {
    final request = http.Request('GET', Uri.parse('$_baseUrl$path'));
    final response = await _sendAuthorized(request, authenticated: true);
    if (response.statusCode >= 200 && response.statusCode < 300) return response.bodyBytes;
    await _throwError(response, authenticated: true);
  }

  Future<ApiResponse> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    bool authenticated = true,
  }) async {
    // queryParameters codifica "+" como %2B (necesario para ?bloodGroup=A%2B)
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: query);
    final request = http.Request(method, uri);

    if (body != null) {
      request.headers['Content-Type'] = 'application/json; charset=utf-8';
      request.body = jsonEncode(body);
    }

    final response = await _sendAuthorized(request, authenticated: authenticated);
    return _jsonResult(response, authenticated: authenticated);
  }

  Future<http.Response> _sendAuthorized(http.BaseRequest request, {required bool authenticated}) async {
    request.headers['Accept'] = 'application/json';

    if (authenticated) {
      final token = _session.validToken;
      if (token == null) {
        await _expireSession();
        throw const ApiException.sessionExpired();
      }
      request.headers['Authorization'] = 'Bearer $token';
    }

    return _execute(request);
  }

  Future<ApiResponse> _jsonResult(http.Response response, {required bool authenticated}) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = _decodeBody(response);
      if (json == null) throw const ApiException.invalidResponse();
      return (statusCode: response.statusCode, body: json);
    }
    await _throwError(response, authenticated: authenticated);
  }

  Future<Never> _throwError(http.Response response, {required bool authenticated}) async {
    // Un 401 con token significa token inválido o vencido. Un 403 no cierra la sesión.
    if (response.statusCode == 401 && authenticated) {
      await _expireSession();
      throw const ApiException.sessionExpired();
    }

    throw ApiException.fromResponse(response.statusCode, _decodeBody(response) ?? const {});
  }

  Future<http.Response> _execute(http.BaseRequest request) async {
    try {
      final streamed = await _httpClient.send(request).timeout(_timeout);
      return await http.Response.fromStream(streamed).timeout(_timeout);
    } on TimeoutException {
      throw const ApiException.timeout();
    } on SocketException {
      throw const ApiException.network();
    } on http.ClientException {
      throw const ApiException.network();
    }
  }

  // Devuelve null si el cuerpo no es un objeto JSON
  Map<String, dynamic>? _decodeBody(http.Response response) {
    if (response.body.isEmpty) return const {};
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  Future<void> _expireSession() async {
    await _session.clear();
    onSessionExpired?.call();
  }
}
