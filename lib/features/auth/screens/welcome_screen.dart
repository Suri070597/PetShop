import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/constants/cloudinary_constants.dart';
import '../../../app/router/route_names.dart';
import '../../../app/theme/colors.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/di/dependency_injection.dart';
import '../../../shared/widgets/primary_button.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  Timer? _autoRedirectTimer;
  int _countdown = 10;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _autoRedirectTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _autoRedirectTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _countdown--);
      if (_countdown <= 0) {
        timer.cancel();
        _startShopping();
      }
    });
  }

  Future<void> _startShopping() async {
    if (_isNavigating) return;
    _isNavigating = true;
    _autoRedirectTimer?.cancel();
    try {
      final user = await ref.read(authRepositoryProvider).currentLocalUser();
      if (user != null) {
        await ref.read(authRepositoryProvider).markWelcomeShown(user);
      }
    } catch (_) {
      // Ignore errors, still navigate to home
    }
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, RouteNames.home, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _WelcomeBackground()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(34),
                        child: Image.network(
                          CloudinaryConstants.welcomePetsUrl,
                          height: 300,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const ColoredBox(color: AppColors.mist),
                        ),
                      ),
                      Positioned(
                        right: -8,
                        bottom: -20,
                        child: Container(
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            color: AppColors.forest,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 6),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.forest.withValues(alpha: 0.24),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.verified_rounded,
                            color: Colors.white,
                            size: 44,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 54),
                  const Text(
                    'Chào mừng đến với gia đình Pet Shop',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.display,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Tài khoản của bạn đã được tạo thành công. Hãy tìm món đồ thật tuyệt cho thú cưng nhé!',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(height: 38),
                  PrimaryButton(
                    label: 'Bắt đầu mua sắm ($_countdown)',
                    icon: Icons.arrow_forward,
                    onPressed: _startShopping,
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _startShopping,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.forest,
                        side: const BorderSide(
                          color: AppColors.forest,
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      icon: const Icon(Icons.home_outlined),
                      label: const Text(
                        'Về Trang chủ ngay',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeBackground extends StatelessWidget {
  const _WelcomeBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WelcomeBackgroundPainter(),
      child: const DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.2,
            colors: [Color(0xFFD8FFD4), Colors.white],
          ),
        ),
      ),
    );
  }
}

class _WelcomeBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      AppColors.honey.withValues(alpha: 0.42),
      AppColors.leaf.withValues(alpha: 0.42),
      AppColors.peach.withValues(alpha: 0.55),
    ];
    for (var i = 0; i < 26; i++) {
      final x = (i * 73 % size.width).toDouble();
      final y = (i * 131 % size.height).toDouble();
      final paint = Paint()..color = colors[i % colors.length];
      final rect = Rect.fromCenter(center: Offset(x, y), width: 12, height: 6);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(i * 0.31);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.shift(Offset(-x, -y)),
          const Radius.circular(3),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
