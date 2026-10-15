import 'package:flutter/material.dart';
import 'package:proyecto_laboratorio_intec/src/constants/validators.dart';
import 'package:proyecto_laboratorio_intec/src/screens/views/auth/forgot_password_screen.dart';
import 'package:proyecto_laboratorio_intec/src/screens/views/auth/register_screen.dart';
import 'package:proyecto_laboratorio_intec/src/screens/views/components/widgets/main_button.dart';

import '../../../repositories/auth_repository.dart';
import '../../../services/app_services.dart';
import '../home/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  static const pageRoute = "/login-screen";
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthRepository _authService = AppServices.instance.auth;

  bool _isLoading = false;
  bool _showPassword = true;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _login() async {
    // Evita enviar el formulario dos veces mientras la petición está en curso
    if (_isLoading) return;

    // 1. Quitar el foco del teclado globalmente
    FocusManager.instance.primaryFocus?.unfocus();

    // 2. Dar tiempo a que la animación de ocultar el teclado finalice
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    // 3. Validar formulario
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // 4. Intentar autenticación
      final response = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      // 5. Si fue exitoso se abre Home y se descarta el historial de autenticación;
      // si no, se muestra el mensaje recibido.
      if (response == "Success") {
        // Los mensajes de autenticación (p. ej. "Account successfully created!") ya no aplican en Home
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        Navigator.pushNamedAndRemoveUntil(context, HomeScreen.pageRoute, (_) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(response),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Welcome Back!",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: emailvalidator.call,
                    decoration: InputDecoration(
                      labelText: "Enter your Email",
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _showPassword,
                    validator: passwordValidator.call,
                    decoration: InputDecoration(
                      labelText: "Enter your Password",
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off
                              : Icons.remove_red_eye,
                        ),
                        onPressed: () {
                          setState(() {
                            _showPassword = !_showPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                      child: Text(
                        "Forgot Your Password?",
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  MainButton(
                    label: "LOGIN",
                    action: _login,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 10),
                  const Text("OR"),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't Have an Account?"),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: Text(
                          "Register Here",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                            fontSize: 18,
                          ),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}