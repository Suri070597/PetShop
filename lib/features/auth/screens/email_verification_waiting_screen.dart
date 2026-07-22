import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/colors.dart';
import '../../../app/theme/text_styles.dart';
import '../../../shared/widgets/auth_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/auth_controller.dart';

enum _VerificationUiState { waiting, checking, success, failed }

class EmailVerificationWaitingScreen extends ConsumerStatefulWidget {
  const EmailVerificationWaitingScreen({super.key});

  @override
  ConsumerState<EmailVerificationWaitingScreen> createState() =>
      _EmailVerificationWaitingScreenState();
}

class _EmailVerificationWaitingScreenState
    extends ConsumerState<EmailVerificationWaitingScreen>
    with WidgetsBindingObserver {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  Timer? _pollingTimer;
  Timer? _autoRedirectTimer;
  _VerificationUiState _uiState = _VerificationUiState.waiting;
  String? _message;
  bool _isHandlingLink = false;
  int _autoRedirectCountdown = 600;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenForVerificationLinks();
    _startPolling();
    _startAutoRedirectCountdown();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _linkSubscription?.cancel();
    _pollingTimer?.cancel();
    _autoRedirectTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkStatus(silent: true);
    }
  }

  Future<void> _listenForVerificationLinks() async {
    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      await _handleIncomingLink(initialLink);
    }

    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleIncomingLink,
      onError: (Object error) {
        setState(() {
          _uiState = _VerificationUiState.failed;
          _message = 'Không thể đọc liên kết xác minh: $error';
        });
      },
    );
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted && _uiState == _VerificationUiState.waiting) {
        _checkStatus(silent: true);
      }
    });
  }

  Future<void> _handleIncomingLink(Uri uri) async {
    if (_isHandlingLink) {
      return;
    }
    _isHandlingLink = true;
    setState(() {
      _uiState = _VerificationUiState.checking;
      _message = 'Đang xử lý liên kết xác minh...';
    });

    try {
      await ref
          .read(authControllerProvider.notifier)
          .applyEmailVerificationLink(uri);
      if (!mounted) {
        return;
      }
      setState(() {
        _uiState = _VerificationUiState.success;
        _message = 'Email đã được xác minh thành công.';
      });
      await Future<void>.delayed(const Duration(milliseconds: 650));
      _goToWelcome();
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _uiState = _VerificationUiState.failed;
          _message = error.toString();
        });
      }
    } finally {
      _isHandlingLink = false;
    }
  }

  Future<void> _checkStatus({bool silent = false}) async {
    if (_isHandlingLink) {
      return;
    }
    if (!silent) {
      setState(() {
        _uiState = _VerificationUiState.checking;
        _message = 'Đang kiểm tra trạng thái xác minh...';
      });
    }

    try {
      await ref
          .read(authControllerProvider.notifier)
          .checkEmailVerificationStatus();
      if (!mounted) {
        return;
      }
      setState(() {
        _uiState = _VerificationUiState.success;
        _message = 'Email đã được xác minh thành công.';
      });
      await Future<void>.delayed(const Duration(milliseconds: 650));
      _goToWelcome();
    } on Object catch (error) {
      if (!silent && mounted) {
        setState(() {
          _uiState = _VerificationUiState.failed;
          _message = error.toString();
        });
      }
    }
  }

  Future<void> _resendEmail() async {
    try {
      await ref.read(authControllerProvider.notifier).resendVerificationEmail();
      if (!mounted) {
        return;
      }
      setState(() {
        _uiState = _VerificationUiState.waiting;
        _message = 'Đã gửi lại email xác minh. Vui lòng kiểm tra hộp thư.';
      });
    } on Object catch (error) {
      setState(() {
        _uiState = _VerificationUiState.failed;
        _message = error.toString();
      });
    }
  }

  void _startAutoRedirectCountdown() {
    _autoRedirectTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _autoRedirectCountdown--;
      });
      if (_autoRedirectCountdown <= 0) {
        timer.cancel();
        _goToHome();
      }
    });
  }

  void _goToHome() {
    if (!mounted) {
      return;
    }
    _autoRedirectTimer?.cancel();
    _pollingTimer?.cancel();
    Navigator.pushNamedAndRemoveUntil(
      context,
      RouteNames.home,
      (_) => false,
    );
  }

  void _goToWelcome() {
    if (!mounted) {
      return;
    }
    _autoRedirectTimer?.cancel();
    _pollingTimer?.cancel();
    Navigator.pushNamedAndRemoveUntil(
      context,
      RouteNames.home,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        ref.watch(authControllerProvider).isLoading ||
        _uiState == _VerificationUiState.checking;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.2,
            colors: [Color(0xFFE1F9DE), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AuthCard(
                child: Column(
                  children: [
                    _StatusIcon(state: _uiState),
                    const SizedBox(height: 34),
                    const Text(
                      'Chờ xác minh email',
                      style: AppTextStyles.title,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'PetJoy đã gửi liên kết xác minh đến email của bạn. Hãy mở email và bấm vào liên kết để hoàn tất.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: 22),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Text(
                        _message ??
                            'Ứng dụng sẽ tự cập nhật khi bạn quay lại sau khi xác minh.',
                        key: ValueKey(_message ?? _uiState.name),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _uiState == _VerificationUiState.failed
                              ? AppColors.danger
                              : AppColors.muted,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    PrimaryButton(
                      label: 'Tôi đã xác minh',
                      icon: Icons.refresh,
                      isLoading: isLoading,
                      onPressed: () => _checkStatus(),
                    ),
                    const SizedBox(height: 14),
                    TextButton.icon(
                      onPressed: isLoading ? null : _resendEmail,
                      icon: const Icon(Icons.mark_email_unread_outlined),
                      label: const Text('Gửi lại email xác minh'),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _goToHome,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.forest,
                          side: const BorderSide(color: AppColors.forest, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        icon: const Icon(Icons.home_outlined),
                        label: Text(
                          'Quay về Trang chủ (${ _autoRedirectCountdown}s)',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
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

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.state});

  final _VerificationUiState state;

  @override
  Widget build(BuildContext context) {
    final icon = switch (state) {
      _VerificationUiState.success => Icons.verified_rounded,
      _VerificationUiState.failed => Icons.error_outline,
      _VerificationUiState.checking => Icons.sync,
      _VerificationUiState.waiting => Icons.mark_email_read_outlined,
    };
    final color = state == _VerificationUiState.failed
        ? AppColors.danger
        : AppColors.leaf;

    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 56),
    );
  }
}
