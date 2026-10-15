enum ApiErrorType {
  validation,
  invalidCredentials,
  sessionExpired,
  forbidden,
  notFound,
  conflict,
  server,
  network,
  timeout,
  invalidResponse,
  unavailable,
  unexpected,
}

class FieldViolation {
  final String field;
  final String message;

  const FieldViolation(this.field, this.message);
}

/// Error de la API ya traducido a un mensaje apto para mostrar al usuario.
class ApiException implements Exception {
  final ApiErrorType type;
  final String message;
  final int? statusCode;
  final List<FieldViolation> fields;

  const ApiException(
    this.type,
    this.message, {
    this.statusCode,
    this.fields = const [],
  });

  const ApiException.sessionExpired()
      : this(ApiErrorType.sessionExpired, 'Your session has expired. Please log in again.', statusCode: 401);

  const ApiException.network()
      : this(ApiErrorType.network, 'Could not connect to the server. Check your connection.');

  const ApiException.timeout()
      : this(ApiErrorType.timeout, 'The server took too long to respond. Try again.');

  const ApiException.invalidResponse()
      : this(ApiErrorType.invalidResponse, 'The server sent an unexpected response.');

  /// Construye la excepción a partir del cuerpo de error de Spring Boot:
  /// {"status", "error", "message", "path", "fields": [{"field", "message"}]}
  factory ApiException.fromResponse(int statusCode, Map<String, dynamic> body) {
    final fields = (body['fields'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((f) => FieldViolation('${f['field']}', '${f['message']}'))
        .toList();

    final serverMessage = body['message'] is String ? body['message'] as String : null;
    final errorCode = body['error'];

    final type = switch (statusCode) {
      400 => ApiErrorType.validation,
      401 when errorCode == 'INVALID_CREDENTIALS' => ApiErrorType.invalidCredentials,
      401 => ApiErrorType.sessionExpired,
      403 => ApiErrorType.forbidden,
      404 => ApiErrorType.notFound,
      409 => ApiErrorType.conflict,
      >= 500 => ApiErrorType.server,
      _ => ApiErrorType.unexpected,
    };

    // Los errores 5xx nunca muestran el detalle del servidor
    final message = switch (type) {
      ApiErrorType.validation when fields.isNotEmpty => fields.first.message,
      ApiErrorType.server => 'The server had a problem. Try again later.',
      ApiErrorType.forbidden => 'You do not have permission to perform this action.',
      _ => serverMessage ?? 'Something went wrong',
    };

    return ApiException(type, message, statusCode: statusCode, fields: fields);
  }

  @override
  String toString() => message;
}
