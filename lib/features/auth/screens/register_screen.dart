import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/colors.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/platform_helper.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/auth_card.dart';
import '../../../shared/widgets/pet_text_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _acceptedTerms = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (!_acceptedTerms) {
      _showMessage('Vui lòng đồng ý điều khoản và chính sách.');
      return;
    }

    try {
      await ref
          .read(authControllerProvider.notifier)
          .registerWithEmail(
            fullName: _nameController.text,
            email: _emailController.text,
            phone: _phoneController.text,
            password: _passwordController.text,
          );
      if (!mounted) {
        return;
      }
      Navigator.pushReplacementNamed(context, RouteNames.verifyAccount);
    } on Object catch (error) {
      _showMessage(error.toString());
    }
  }

  Future<void> _googleSignUp() async {
    try {
      await ref.read(authControllerProvider.notifier).signInWithGoogle();
      if (!mounted) {
        return;
      }
      Navigator.pushReplacementNamed(context, RouteNames.welcome);
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
    final showGoogleSignUp = !PlatformHelper.isWindows;

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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: const BoxDecoration(
                        color: AppColors.leaf,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.pets,
                        color: AppColors.ink,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text('Đăng ký', style: AppTextStyles.title),
                    const SizedBox(height: 12),
                    const Text(
                      'Bắt đầu chỉ trong một phút.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body,
                    ),
                    if (showGoogleSignUp) ...[
                      const SizedBox(height: 28),
                      _SoftButton(
                        label: 'Đăng ký bằng Google',
                        onPressed: isLoading ? null : _googleSignUp,
                      ),
                      const SizedBox(height: 28),
                      const _EmailDivider(),
                      const SizedBox(height: 24),
                    ] else
                      const SizedBox(height: 28),
                    PetTextField(
                      controller: _nameController,
                      labelText: 'Họ và tên',
                      hintText: 'Nguyễn An',
                      validator: (value) =>
                          Validators.required(value, 'họ và tên'),
                    ),
                    const SizedBox(height: 16),
                    PetTextField(
                      controller: _emailController,
                      labelText: 'Địa chỉ email',
                      hintText: 'an@example.com',
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 16),
                    PetTextField(
                      controller: _phoneController,
                      labelText: 'Số điện thoại',
                      hintText: '0900 000 000',
                      keyboardType: TextInputType.phone,
                      validator: (value) =>
                          Validators.required(value, 'số điện thoại'),
                    ),
                    const SizedBox(height: 16),
                    PetTextField(
                      controller: _passwordController,
                      labelText: 'Mật khẩu',
                      hintText: '••••••••',
                      obscureText: _obscurePassword,
                      validator: Validators.password,
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    PetTextField(
                      controller: _confirmPasswordController,
                      labelText: 'Nhập lại mật khẩu',
                      hintText: '••••••••',
                      obscureText: true,
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Mật khẩu nhập lại không khớp';
                        }
                        return Validators.password(value);
                      },
                    ),
                    const SizedBox(height: 22),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _acceptedTerms,
                          shape: const CircleBorder(),
                          side: const BorderSide(
                            color: AppColors.line,
                            width: 2,
                          ),
                          onChanged: (value) =>
                              setState(() => _acceptedTerms = value ?? false),
                        ),
                        const Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(top: 10),
                            child: Text.rich(
                              TextSpan(
                                text: 'Tôi đồng ý với ',
                                children: [
                                  TextSpan(
                                    text: 'Điều khoản',
                                    style: TextStyle(
                                      color: AppColors.forest,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  TextSpan(text: ' và xác nhận '),
                                  TextSpan(
                                    text: 'Chính sách bảo mật',
                                    style: TextStyle(
                                      color: AppColors.forest,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  TextSpan(text: '.'),
                                ],
                              ),
                              style: AppTextStyles.body,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Đăng ký',
                      isLoading: isLoading,
                      onPressed: _register,
                    ),
                    const SizedBox(height: 28),
                    Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        const Text(
                          'Đã có tài khoản? ',
                          style: AppTextStyles.body,
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacementNamed(
                            context,
                            RouteNames.login,
                          ),
                          child: const Text(
                            'Đăng nhập tại đây',
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

class _SoftButton extends StatelessWidget {
  const _SoftButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.peach,
          foregroundColor: AppColors.forest,
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
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmailDivider extends StatelessWidget {
  const _EmailDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: AppColors.line)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            'HOẶC EMAIL',
            style: TextStyle(letterSpacing: 0, color: AppColors.ink),
          ),
        ),
        Expanded(child: Divider(color: AppColors.line)),
      ],
    );
  }
}
