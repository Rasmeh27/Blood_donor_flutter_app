const _months = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

String _twoDigits(int value) => value.toString().padLeft(2, '0');

/// Fecha de calendario en el formato de la API (yyyy-MM-dd), sin conversión de zona horaria.
String toApiDate(DateTime date) =>
    '${date.year}-${_twoDigits(date.month)}-${_twoDigits(date.day)}';

/// Lee "yyyy-MM-dd" como fecha local (sin hora), evitando desplazamientos por zona horaria.
DateTime parseApiDate(String value) {
  final parts = value.split('-').map(int.parse).toList();
  return DateTime(parts[0], parts[1], parts[2]);
}

/// Timestamp de la API (ISO 8601 en UTC, p. ej. "2026-10-14T22:27:06Z") convertido a hora local.
/// A diferencia de las fechas de calendario, representa un instante exacto.
DateTime parseTimestamp(String value) => DateTime.parse(value).toLocal();

/// Formato de las tarjetas y del detalle: "10 February 2024".
String toLongDate(DateTime date) => '${date.day} ${_months[date.month - 1]} ${date.year}';

/// Formato del calendario original (FindDonorDatePicker): "10-2-2024".
String toPickerDate(DateTime date) => '${date.day}-${date.month}-${date.year}';

/// Texto relativo del feed, con el mismo estilo del diseño ("2 minute ago").
String timeAgo(DateTime createdAt, {DateTime? now}) {
  final elapsed = (now ?? DateTime.now()).difference(createdAt);
  if (elapsed.inMinutes < 1) return 'just now';
  if (elapsed.inHours < 1) return '${elapsed.inMinutes} minute ago';
  if (elapsed.inDays < 1) return '${elapsed.inHours} hour ago';
  return '${elapsed.inDays} day ago';
}

DateTime today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}
