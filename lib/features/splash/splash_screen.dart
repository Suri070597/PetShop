import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router/route_names.dart';
import '../../app/theme/colors.dart';
import '../../app/theme/text_styles.dart';
import '../../shared/widgets/pet_logo.dart';

import '../../core/di/dependency_injection.dart';
import '../../data/datasources/drift/app_database.dart';
import '../auth/providers/auth_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final startTime = DateTime.now();
    LocalUser? user;
    try {
      user = await ref.read(authControllerProvider.notifier).restoreSession();
    } catch (_) {
      user = null;
    }

    final elapsed = DateTime.now().difference(startTime);
    const minDelay = Duration(milliseconds: 900);
    if (elapsed < minDelay) {
      await Future<void>.delayed(minDelay - elapsed);
    }

    if (!mounted) {
      return;
    }

    if (user != null && !user.emailVerified) {
      // Sign out unverified account so user opens app as a Guest
      await ref.read(authControllerProvider.notifier).signOut();
      if (!mounted) {
        return;
      }
      Navigator.pushReplacementNamed(context, RouteNames.home);
      return;
    }

    if (user == null) {
      Navigator.pushReplacementNamed(context, RouteNames.home);
      return;
    }

    final authRepo = ref.read(authRepositoryProvider);
    if (authRepo.shouldShowWelcome(user)) {
      Navigator.pushReplacementNamed(context, RouteNames.welcome);
    } else {
      Navigator.pushReplacementNamed(context, RouteNames.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _PawPattern()),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 210,
                      height: 210,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFD6F0D8),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.leaf.withValues(alpha: 0.14),
                            blurRadius: 42,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const PetLogo(size: 108),
                    ),
                    const SizedBox(height: 32),
                    const Text('PetJoy', style: AppTextStyles.display),
                    const SizedBox(height: 12),
                    const Text(
                      'Mọi điều thú cưng cần',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: 28),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _Dot(),
                        SizedBox(width: 10),
                        _Dot(),
                        SizedBox(width: 10),
                        _Dot(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: 10,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.leaf,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _PawPattern extends StatelessWidget {
  const _PawPattern();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _PawPatternPainter());
  }
}

class _PawPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.leaf.withValues(alpha: 0.045);
    const stepX = 56.0;
    const stepY = 58.0;
    for (double y = 20; y < size.height; y += stepY) {
      for (double x = 24; x < size.width; x += stepX) {
        canvas.drawCircle(Offset(x, y), 3, paint);
        canvas.drawCircle(Offset(x + 10, y + 8), 2.4, paint);
        canvas.drawCircle(Offset(x - 9, y + 8), 2.4, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
