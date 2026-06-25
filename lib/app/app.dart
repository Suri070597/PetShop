import 'package:flutter/material.dart';

import '../features/auth/screens/email_verification_waiting_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/welcome_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/splash/splash_screen.dart';
import 'router/route_names.dart';
import 'theme/app_theme.dart';

class PetShopApp extends StatelessWidget {
  const PetShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PetJoy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: RouteNames.splash,
      routes: {
        RouteNames.splash: (_) => const SplashScreen(),
        RouteNames.login: (_) => const LoginScreen(),
        RouteNames.register: (_) => const RegisterScreen(),
        RouteNames.verifyAccount: (_) => const EmailVerificationWaitingScreen(),
        RouteNames.welcome: (_) => const WelcomeScreen(),
        RouteNames.home: (_) => const HomeScreen(),
        RouteNames.profile: (_) => const ProfileScreen(),
      },
    );
  }
}
