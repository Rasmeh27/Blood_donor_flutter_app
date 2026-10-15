// Reglas de validación de los formularios de solicitud y donante. Son las mismas del backend
// (CreateBloodRequest y DonorRequest) para detectar errores antes de enviar.

final _phonePattern = RegExp(r'^\+?[0-9]{7,15}$');

const maxBagsPerRequest = 10;

/// Quita espacios, guiones y paréntesis: "+1 (809) 224-9304" -> "+18092249304".
String normalizePhone(String value) => value.replaceAll(RegExp(r'[\s\-()]'), '');

String? requiredText(String value, String fieldName, {int? maxLength}) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '$fieldName is required';
  if (maxLength != null && trimmed.length > maxLength) {
    return '$fieldName must have at most $maxLength characters';
  }
  return null;
}

String? phoneNumber(String value, String fieldName) {
  if (value.trim().isEmpty) return '$fieldName is required';
  return _phonePattern.hasMatch(normalizePhone(value))
      ? null
      : '$fieldName must have between 7 and 15 digits';
}

String? numberOfBags(String value) {
  final bags = int.tryParse(value.trim());
  if (bags == null) return 'Number of bags is required';
  if (bags < 1 || bags > maxBagsPerRequest) {
    return 'Number of bags must be between 1 and $maxBagsPerRequest';
  }
  return null;
}

/// Primer mensaje de error de la lista, o null si todos los campos son válidos.
String? firstError(List<String? Function()> checks) {
  for (final check in checks) {
    final error = check();
    if (error != null) return error;
  }
  return null;
}
