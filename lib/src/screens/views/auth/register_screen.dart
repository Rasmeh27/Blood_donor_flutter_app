
import 'package:flutter/material.dart';
import 'package:proyecto_laboratorio_intec/src/constants/validators.dart';
import 'package:proyecto_laboratorio_intec/src/services/app_services.dart';

import '../../../repositories/auth_repository.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  static const pageRoute = "/register-screen";
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  final _formKey = GlobalKey<FormState>();

  final AuthRepository _authService = AppServices.instance.auth;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  //crear una variable para mostrar un spinning
  bool _isLoading = false;

  // Controlado por el botón "Show Password" (aplica a ambos campos de contraseña)
  bool _showPasswords = false;

  String? _validateConfirmPassword(String? value) {
    final error = passwordValidator.call(value);
    if (error != null) return error;
    return value == _passwordController.text ? null : 'passwords do not match';
  }

  // Register solo se abre desde Login: se regresa a esa pantalla en lugar de apilar otra
  void _goToLogin() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, LoginScreen.pageRoute);
    }
  }

  //metodo para registrar al usuario
  Future<void> _register() async{
    // Evita registros duplicados por toques repetidos
    if (_isLoading) return;

    //1.-validar el formulario
    if(_formKey.currentState!.validate()){
      setState(() {
        _isLoading = true; //para poder mostrar el spinning
      });

      //2.-Ejecutar el registro
      final response = await _authService.register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          // Sin trim: el login envía la contraseña tal cual y ambas deben coincidir
          password: _passwordController.text
      );

      //3.-Vamos a asegurarnos de que si el usuario cierra
      //la pantalla, la aplicacion no de error
      if(!mounted) return;

      setState(() {
        _isLoading = false; //detengo el spinning
      });

      //4.-Manejar la respuesta
      if(response == "Success"){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Account successfully created!")),
        );

        //navegamos al login para iniciar sesión con la cuenta nueva
        _goToLogin();

      }else{
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text(response)),
        );
      }

    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Create Your Account!',
                        style: TextStyle(
                          fontSize: 32.0,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD32F2F), // Rojo vibrante/médico
                          letterSpacing: 1.0,
                        ),
                      ),
                      SizedBox(
                        height: 40,
                      ),
                      TextFormField(
                        controller: _nameController,
                        validator: nameValidator.call,
                        decoration: InputDecoration(
                            labelText: "Enter your name",
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Theme.of(context).primaryColor,
                                )
                            )
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      TextFormField(
                        controller: _emailController,
                        validator: emailvalidator.call,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                            labelText: "Enter your email",
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Theme.of(context).primaryColor,
                                )
                            )
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      TextFormField(
                        controller: _passwordController,
                        validator: passwordValidator.call,
                        obscureText: !_showPasswords,
                        decoration: InputDecoration(
                          labelText: "Enter your password",
                          prefixIcon: Icon(Icons.lock),
                          //suffixIcon: Icon(Icons.remove_red_eye),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).primaryColor,
                              )
                          ),

                        ),
                      ),
                      SizedBox(height: 20,),
                      TextFormField(
                        controller: _confirmPasswordController,
                        validator: _validateConfirmPassword,
                        obscureText: !_showPasswords,
                        decoration: InputDecoration(
                          labelText: "Confirm your password",
                          prefixIcon: Icon(Icons.lock),
                          //suffixIcon: Icon(Icons.remove_red_eye),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).primaryColor,
                              )
                          ),

                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('Show Password'),
                            IconButton(
                                onPressed: () => setState(() => _showPasswords = !_showPasswords),
                                icon: Icon(Icons.remove_red_eye)),
                          ],
                        ),
                      ),

                      SizedBox(height: 50,),
                      ElevatedButton(
                        onPressed: (){
                          //llamar al metodo que ejecute el registro
                          _register();
                        },
                        child: _isLoading
                            ? CircularProgressIndicator()
                            : Text("REGISTER", style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),),
                        style: ElevatedButton.styleFrom(
                            minimumSize: Size.fromHeight(60),
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            )
                        ),
                      ),
                      SizedBox(height: 10,),
                      Text("OR"),
                      SizedBox(height: 10,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Already Have An Account?"),
                          SizedBox(width: 10,),
                          InkWell(
                            onTap: _goToLogin,
                            child: Text("Login Here", style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Theme.of(context).primaryColor,
                            ),),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
      ),
    );
  }
}