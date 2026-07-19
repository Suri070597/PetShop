import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/auth_card.dart';
import '../../../shared/widgets/pet_logo.dart';
import '../../../shared/widgets/pet_text_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/auth_controller.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      await ref
          .read(authControllerProvider.notifier)
          .sendPasswordResetEmail(_emailController.text);
      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Email đã được gửi'),
          content: const Text('Vui lòng kiểm tra hộp thư để đặt lại mật khẩu.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (!mounted) {
        return;
      }
      Navigator.pushReplacementNamed(context, RouteNames.login);
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

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
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
                    const PetLogo(size: 82),
                    const SizedBox(height: 30),
                    const Text('Quên mật khẩu', style: AppTextStyles.title),
                    const SizedBox(height: 12),
                    const Text(
                      'Nhập email tài khoản để nhận liên kết đặt lại mật khẩu.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: 30),
                    PetTextField(
                      controller: _emailController,
                      hintText: 'Địa chỉ email',
                      icon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Gửi email đặt lại',
                      icon: Icons.mark_email_read_outlined,
                      isLoading: isLoading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 18),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () => Navigator.pushReplacementNamed(
                              context,
                              RouteNames.login,
                            ),
                      child: const Text('Quay lại đăng nhập'),
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
