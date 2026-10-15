import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:proyecto_laboratorio_intec/src/constants/validators.dart';
import 'package:proyecto_laboratorio_intec/src/screens/views/auth/otp_recovery_screen.dart';
import 'package:proyecto_laboratorio_intec/src/screens/views/components/widgets/main_button.dart';
import 'package:proyecto_laboratorio_intec/src/repositories/auth_repository.dart';
import 'package:proyecto_laboratorio_intec/src/services/app_services.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {

  final emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthRepository _authService = AppServices.instance.auth;

  bool _isLoading = false;

  Future<void> _handleResetPassword() async{
    if (_isLoading) return;
    if(_formKey.currentState!.validate()){
      setState(() {
        _isLoading = true;
      });

      try{
        final email = emailController.text.trim();
        await _authService.sendPasswordResetEmail(email);

        if(!mounted) return;

        // El servidor responde igual exista o no la cuenta (no revela correos registrados)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("If the email is registered, you will receive a verification code"),
          backgroundColor: Colors.green,
        ),
          );
        _openCodeVerification(email);

      }catch(error){
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString(),
        ),
          backgroundColor: Theme.of(context).primaryColor,
        ),
        );
      } finally{
        if(mounted){
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }


  void _openCodeVerification(String email) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => OtpRecoveryScreen(email: email),));
  }

  // Para quien ya recibió un código: requiere el correo para poder verificarlo
  void _openVerificationWithTypedEmail() {
    if (emailvalidator.call(emailController.text.trim()) != null) {
      _formKey.currentState!.validate();
      return;
    }
    _openCodeVerification(emailController.text.trim());
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
                Text('Forgot Password', style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold
                ),
                ),
                SizedBox(height: 60,),
                Text("Please enter your email address. You will receive a link to reset you password",
                  style: TextStyle(fontSize: 15),
                ),
                SizedBox(height: 20,),
                TextFormField(
                  validator: emailvalidator.call,
                  controller: emailController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Email",
                    suffix: InkWell(
                      onTap: () {
                        setState(() {
                          //limpiar el controlador
                          emailController.clear();
                        });
                      },
                      child: Icon(CupertinoIcons.multiply),
                    )
                  ),
                ),
                SizedBox(height: 30,),
                MainButton(
                    label: "SEND",
                    action: () {
                      //hacemos la logica para el reset
                      _handleResetPassword();
                      //adicionl navegamos a la pantalla de recovery
                      //Navigator.push(context, MaterialPageRoute(builder: (context) => RecoveryScreen(),));
                    },
                    isLoading: _isLoading,
                ),
                SizedBox(height: 10,),
                Text("OR"),
                SizedBox(height: 10,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 10,),
                    InkWell(
                      //navegamos a la pantalla de OTP
                      onTap: _openVerificationWithTypedEmail,
                      child: Text("Verify Using Number Here", style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Theme.of(context).primaryColor
                      ),),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
