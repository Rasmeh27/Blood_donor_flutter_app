import 'dart:async';

import 'package:flutter/material.dart';

import '../../../services/app_services.dart';
import '../home/screens/home_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  static const pageRoute = "/splash-screen";
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(Duration(seconds: 3), () {
      if (!mounted) return;
      // Sesión restaurada en main.dart: se omite Onboarding/Login si el token sigue vigente
      if (AppServices.instance.session.isActive) {
        Navigator.pushReplacementNamed(context, HomeScreen.pageRoute);
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => OnboardingScreen(),));
      }
    },);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color: Colors.black,
          image: DecorationImage(image: AssetImage('assets/images/splash.png'),
            fit: BoxFit.cover,
            opacity: 0.6,
          ),
        ),
      ),
    );
  }
}

