import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/colors.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/di/dependency_injection.dart';
import '../../../core/utils/platform_helper.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/auth_card.dart';
import '../../../shared/widgets/pet_logo.dart';
import '../../../shared/widgets/pet_text_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    try {
      final user = await ref
          .read(authControllerProvider.notifier)
          .signInWithEmail(
            email: _emailController.text,
            password: _passwordController.text,
          );
      if (!mounted) {
        return;
      }
      if (!user.emailVerified) {
        Navigator.pushReplacementNamed(context, RouteNames.verifyAccount);
        return;
      }
      Navigator.pushReplacementNamed(context, RouteNames.home);
    } on Object catch (error) {
      _showMessage(error.toString());
    }
  }

  Future<void> _googleLogin() async {
    try {
      final user = await ref
          .read(authControllerProvider.notifier)
          .signInWithGoogle();
      if (!mounted) {
        return;
      }
      final route = ref.read(authRepositoryProvider).shouldShowWelcome(user)
          ? RouteNames.welcome
          : RouteNames.home;
      Navigator.pushReplacementNamed(context, route);
    } on Object catch (error) {
      _showMessage(error.toString());
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;
    final showGoogleLogin = !PlatformHelper.isWindows;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: AuthCard(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pushReplacementNamed(
                        context,
                        RouteNames.home,
                      ),
                      child: const PetLogo(size: 82),
                    ),
                    const SizedBox(height: 34),
                    const Text(
                      'Chào mừng trở lại!',
                      style: AppTextStyles.title,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Đăng nhập để tiếp tục chăm sóc những người bạn nhỏ.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: 34),
                    PetTextField(
                      controller: _emailController,
                      hintText: 'Địa chỉ email',
                      icon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 18),
                    PetTextField(
                      controller: _passwordController,
                      hintText: 'Mật khẩu',
                      icon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      validator: Validators.password,
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          RouteNames.forgotPassword,
                        ),
                        child: const Text('Quên mật khẩu?'),
                      ),
                    ),
                    PrimaryButton(
                      label: 'Đăng nhập',
                      icon: Icons.login,
                      isLoading: isLoading,
                      onPressed: _login,
                    ),
                    if (showGoogleLogin) ...[
                      const SizedBox(height: 24),
                      const _DividerText(),
                      const SizedBox(height: 24),
                      _GoogleButton(onPressed: isLoading ? null : _googleLogin),
                    ],
                    const SizedBox(height: 32),
                    Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        const Text(
                          'Bạn chưa có tài khoản? ',
                          style: AppTextStyles.body,
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacementNamed(
                            context,
                            RouteNames.register,
                          ),
                          child: const Text(
                            'Đăng ký',
                            style: TextStyle(
                              color: AppColors.forest,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DividerText extends StatelessWidget {
  const _DividerText();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.line)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'hoặc',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.line)),
      ],
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFE2E2E2),
          foregroundColor: AppColors.ink,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'G',
              style: TextStyle(
                color: Color(0xFF4285F4),
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Tiếp tục với Google',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
