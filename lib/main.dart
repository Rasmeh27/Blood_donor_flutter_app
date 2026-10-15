import 'package:flutter/material.dart';

import 'src/general/config/colors.dart';
import 'src/general/config/config.dart';
import 'src/screens/views/all_request_details/screens/request_details_screen.dart';
import 'src/screens/views/all_requests/screens/all_request_screen.dart';
import 'src/screens/views/auth/login_screen.dart';
import 'src/screens/views/auth/register_screen.dart';
import 'src/screens/views/donor_registration/screens/donor_registration_screen.dart';
import 'src/screens/views/donor_search/screens/donor_search_screen.dart';
import 'src/screens/views/edit_profile/screens/edit_profile_screen.dart';
import 'src/screens/views/find_donor/screens/find_donor_screen.dart';
import 'src/screens/views/home/screens/home_screen.dart';
import 'src/screens/views/onboarding/splash_screen.dart';
import 'src/screens/views/profile/screens/profile_screen.dart';
import 'src/services/app_services.dart';

final appNavigatorKey = GlobalKey<NavigatorState>();
final appMessengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final services = AppServices.instance;
  await services.session.restore();
  services.apiClient.onSessionExpired = _returnToLogin;

  runApp(const ValideiApp());
}

bool _returningToLogin = false;

// Varias peticiones pueden fallar a la vez con 401: solo se redirige una vez
void _returnToLogin() {
  if (_returningToLogin) return;
  _returningToLogin = true;

  appNavigatorKey.currentState
      ?.pushNamedAndRemoveUntil(LoginScreen.pageRoute, (_) => false);
  appMessengerKey.currentState?.showSnackBar(
    const SnackBar(content: Text('Your session has expired. Please log in again.')),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) => _returningToLogin = false);
}

class ValideiApp extends StatelessWidget {
  const ValideiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConfig.appName,
      navigatorKey: appNavigatorKey,
      scaffoldMessengerKey: appMessengerKey,
      theme: ThemeData(
        primaryColor: AppColor.redColor,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColor.redColor),
      ),
      // Flujo original: Splash -> (sesión guardada ? Home : Onboarding -> Login)
      initialRoute: SplashScreen.pageRoute,
      routes: appRoutes,
    );
  }
}

final appRoutes = <String, WidgetBuilder>{
  HomeScreen.pageRoute: (_) => const HomeScreen(),
  SplashScreen.pageRoute: (_) => const SplashScreen(),
  LoginScreen.pageRoute: (_) => const LoginScreen(),
  RegisterScreen.pageRoute: (_) => const RegisterScreen(),
  DonorRegistrationForm.pageRoute: (_) => const DonorRegistrationForm(),
  FindDonorScreen.pageRoute: (_) => const FindDonorScreen(),
  AllRequestScreen.pageRoute: (_) => const AllRequestScreen(),
  ProfileScreen.pageRoute: (_) => const ProfileScreen(),
  EditProfileScreen.pageRoute: (_) => const EditProfileScreen(),
  RequestDetailsScreen.pageRoute: (_) => const RequestDetailsScreen(),
  DonorSearchScreen.pageRoute: (_) => const DonorSearchScreen(),
};
