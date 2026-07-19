import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/validators.dart';
import '../../../shared/widgets/pet_text_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/profile_controller.dart';
import 'profile_screen.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _currentPasswordError;
  bool _isSubmitting = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _currentPasswordController.addListener(_clearCurrentPasswordError);
  }

  @override
  void dispose() {
    _currentPasswordController.removeListener(_clearCurrentPasswordError);
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _clearCurrentPasswordError() {
    if (_currentPasswordError == null) {
      return;
    }
    setState(() => _currentPasswordError = null);
  }

  Future<void> _save() async {
    debugPrint('Bước 1: Validate');
    setState(() => _currentPasswordError = null);
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      debugPrint('UI: gọi Provider đổi mật khẩu');
      await ref
          .read(profileControllerProvider.notifier)
          .changePassword(
            currentPassword: _currentPasswordController.text,
            newPassword: _newPasswordController.text,
          );
      ref.invalidate(profileSummaryProvider);
      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Đổi mật khẩu thành công'),
          content: const Text(
            'Bạn có thể dùng mật khẩu mới từ lần đăng nhập sau.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } on Object catch (error) {
      final message = error.toString();
      if (message.contains('Mật khẩu hiện tại không đúng')) {
        setState(
          () => _currentPasswordError = 'Mật khẩu hiện tại không chính xác.',
        );
        _formKey.currentState?.validate();
        return;
      }
      _showMessage(message);
    } finally {
      debugPrint('UI: kết thúc loading đổi mật khẩu');
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
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
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(title: const Text('Đổi mật khẩu')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    PetTextField(
                      controller: _currentPasswordController,
                      labelText: 'Mật khẩu hiện tại',
                      hintText: '••••••••',
                      obscureText: _obscureCurrent,
                      validator: (value) =>
                          Validators.required(value, 'mật khẩu hiện tại') ??
                          _currentPasswordError,
                      suffixIcon: _PasswordToggle(
                        obscure: _obscureCurrent,
                        onPressed: () =>
                            setState(() => _obscureCurrent = !_obscureCurrent),
                      ),
                    ),
                    const SizedBox(height: 16),
                    PetTextField(
                      controller: _newPasswordController,
                      labelText: 'Mật khẩu mới',
                      hintText: '••••••••',
                      obscureText: _obscureNew,
                      validator: Validators.password,
                      suffixIcon: _PasswordToggle(
                        obscure: _obscureNew,
                        onPressed: () =>
                            setState(() => _obscureNew = !_obscureNew),
                      ),
                    ),
                    const SizedBox(height: 16),
                    PetTextField(
                      controller: _confirmPasswordController,
                      labelText: 'Nhập lại mật khẩu mới',
                      hintText: '••••••••',
                      obscureText: _obscureConfirm,
                      validator: (value) {
                        final requiredError = Validators.required(
                          value,
                          'nhập lại mật khẩu mới',
                        );
                        if (requiredError != null) {
                          return requiredError;
                        }
                        if (value != _newPasswordController.text) {
                          return 'Mật khẩu nhập lại không khớp';
                        }
                        return null;
                      },
                      suffixIcon: _PasswordToggle(
                        obscure: _obscureConfirm,
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    const SizedBox(height: 28),
                    PrimaryButton(
                      label: 'Cập nhật mật khẩu',
                      icon: Icons.lock_reset_outlined,
                      isLoading: _isSubmitting,
                      onPressed: _save,
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

class _PasswordToggle extends StatelessWidget {
  const _PasswordToggle({required this.obscure, required this.onPressed});

  final bool obscure;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      ),
    );
  }
}
