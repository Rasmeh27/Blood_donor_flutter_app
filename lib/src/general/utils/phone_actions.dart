import 'package:url_launcher/url_launcher.dart';

/// Abre la app de teléfono o de mensajes del dispositivo. Devuelve false si no se pudo.
Future<bool> openPhoneAction(PhoneAction action, String phoneNumber) async {
  final uri = Uri(scheme: action.scheme, path: phoneNumber);
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on Exception {
    return false;
  }
}

enum PhoneAction {
  call('tel'),
  message('sms');

  final String scheme;

  const PhoneAction(this.scheme);
}
