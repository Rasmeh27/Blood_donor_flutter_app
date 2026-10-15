import 'package:flutter/material.dart';
import 'package:flutter_otp_kit/flutter_otp_kit.dart';
import 'package:proyecto_laboratorio_intec/src/repositories/auth_repository.dart';
import 'package:proyecto_laboratorio_intec/src/screens/views/auth/recovery_screen.dart';
import 'package:proyecto_laboratorio_intec/src/screens/views/components/widgets/main_button.dart';
import 'package:proyecto_laboratorio_intec/src/services/api/api_exception.dart';
import 'package:proyecto_laboratorio_intec/src/services/app_services.dart';

/// Verifica el código enviado por correo antes de pasar a RecoveryScreen.
class OtpRecoveryScreen extends StatefulWidget {
  // El código de 6 dígitos coincide con el que genera el backend
  static const codeLength = 6;

  final String email;

  const OtpRecoveryScreen({super.key, required this.email});

  @override
  State<OtpRecoveryScreen> createState() => _OtpRecoveryScreenState();
}

class _OtpRecoveryScreenState extends State<OtpRecoveryScreen> {
  final AuthRepository _authService = AppServices.instance.auth;

  String _code = '';
  bool _isVerifying = false;

  Future<void> _verify() async {
    if (_isVerifying) return;
    if (_code.length != OtpRecoveryScreen.codeLength) {
      _showMessage('Enter the ${OtpRecoveryScreen.codeLength}-digit code sent to your email', isError: true);
      return;
    }

    setState(() => _isVerifying = true);
    try {
      await _authService.verifyResetCode(email: widget.email, code: _code);
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => RecoveryScreen(email: widget.email, code: _code),
      ));
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message, isError: true);
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resend() async {
    try {
      await _authService.sendPasswordResetEmail(widget.email);
      if (mounted) _showMessage('A new code was sent to your email');
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message, isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        backgroundColor: isError ? Colors.red : null,
        content: Text(message),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: OtpKit(
        fieldCount: OtpRecoveryScreen.codeLength,
        // 6 casillas de tamaño original: con el espaciado por defecto (12) la última no cabe en 411 dp
        fieldSpacing: 8,
        buttonWidget: MainButton(
            label: "Verify",
            action: _verify,
            isLoading: _isVerifying
        ),
        title: "Verify",
          titleStyle: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold
          ),
          onChanged: (otp) => _code = otp,
          onCompleted: (otp) => _code = otp,
          // OtpKit solo usa onVerify con su botón propio; aquí verifica el MainButton del diseño
          onVerify: (otp) async {
            _code = otp;
            await _verify();
            return true;
          },
          onResend: _resend,
      ),
    );
  }
}
