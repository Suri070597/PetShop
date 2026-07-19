import 'package:flutter/material.dart';

import '../features/auth/screens/email_verification_waiting_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/welcome_screen.dart';
import '../features/cart/presentation/screens/cart_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/products/presentation/screens/product_detail_screen.dart';
import '../features/products/presentation/screens/product_list_screen.dart';
import '../features/profile/screens/change_password_screen.dart';
import '../features/profile/screens/edit_profile_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/wishlist/presentation/screens/wishlist_screen.dart';
import '../features/vouchers/presentation/screens/vouchers_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
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
        RouteNames.forgotPassword: (_) => const ForgotPasswordScreen(),
        RouteNames.verifyAccount: (_) => const EmailVerificationWaitingScreen(),
        RouteNames.welcome: (_) => const WelcomeScreen(),
        RouteNames.home: (_) => const HomeScreen(),
        RouteNames.profile: (_) => const ProfileScreen(),
        RouteNames.cart: (_) => const CartScreen(),
        RouteNames.productList: (_) => const ProductListScreen(),
        RouteNames.wishlist: (_) => const WishlistScreen(),
        RouteNames.vouchers: (_) => const VouchersScreen(),
        RouteNames.notifications: (_) => const NotificationsScreen(),
        RouteNames.editProfile: (_) => const EditProfileScreen(),
        RouteNames.changePassword: (_) => const ChangePasswordScreen(),
      },
      onGenerateRoute: (settings) {
        // Handle routes with arguments
        if (settings.name == RouteNames.productDetail) {
          final productId = settings.arguments as int? ?? 0;
          return MaterialPageRoute(
            builder: (_) => ProductDetailScreen(productId: productId),
            settings: settings,
          );
        }
        if (settings.name == RouteNames.productList) {
          final initialCategory = settings.arguments as String?;
          return MaterialPageRoute(
            builder: (_) => ProductListScreen(initialCategory: initialCategory),
            settings: settings,
          );
        }
        return null;
      },
    );
  }
}