import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../constants/validators.dart';
import '../../../repositories/auth_repository.dart';
import '../../../services/api/api_exception.dart';
import '../../../services/app_services.dart';
import '../components/widgets/main_button.dart';
import 'login_screen.dart';

/// Último paso de la recuperación: el código ya verificado y la nueva contraseña.
class RecoveryScreen extends StatefulWidget {
  final String email;
  final String code;

  const RecoveryScreen({super.key, required this.email, required this.code});

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  late final codeController = TextEditingController(text: widget.code);

  final _formKey = GlobalKey<FormState>();
  final AuthRepository _authService = AppServices.instance.auth;
  bool _isLoading = false;

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    codeController.dispose();
    super.dispose();
  }

  String? _validateCode(String? value) =>
      RegExp(r'^\d{6}$').hasMatch(value?.trim() ?? '') ? null : 'enter the 6-digit code';

  String? _validateConfirmPassword(String? value) {
    final error = passwordValidator.call(value);
    if (error != null) return error;
    return value == passwordController.text ? null : 'passwords do not match';
  }

  Future<void> _resetPassword() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _authService.resetPassword(
        email: widget.email,
        code: codeController.text.trim(),
        newPassword: passwordController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: Colors.green,
        content: Text('Password updated. Log in with your new password.'),
      ));
      Navigator.pushNamedAndRemoveUntil(context, LoginScreen.pageRoute, (_) => false);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        content: Text(error.message),
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Form(
            key: _formKey,
            child: Column(
            children: [
              SizedBox(
                height: 10,
              ),
              Text('Recover your Account', style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold
              ),
              ),
              SizedBox(height: 60,),
              TextFormField(
                controller: codeController,
                validator: _validateCode,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "# reset code",
                    suffix: InkWell(
                      onTap: () {
                        setState(() {
                          codeController.clear();
                        });
                      },
                      child: Icon(CupertinoIcons.multiply),
                    )
                ),
              ),
              SizedBox(height: 20,),
              TextFormField(
                obscureText: true,
                controller: passwordController,
                validator: passwordValidator.call,
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "New Password",
                    suffix: InkWell(
                      onTap: () {
                        setState(() {
                          passwordController.clear();
                        });
                      },
                      child: Icon(CupertinoIcons.multiply),
                    )
                ),
              ),
              SizedBox(height: 20,),
              TextFormField(
                obscureText: true,
                controller: confirmPasswordController,
                validator: _validateConfirmPassword,
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Confirm Password",
                    suffix: InkWell(
                      onTap: () {
                        setState(() {
                          confirmPasswordController.clear();
                        });
                      },
                      child: Icon(CupertinoIcons.multiply),
                    )
                ),
              ),
              SizedBox(height: 30,),
              MainButton(
                  label: "RESET PASSWORD",
                  action: _resetPassword,
                  isLoading: _isLoading
              ),
              SizedBox(height: 10,),

            ],
          ),
          ),
        ),
      ),
    );
  }
}
