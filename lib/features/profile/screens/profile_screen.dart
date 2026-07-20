import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/constants/cloudinary_constants.dart';
import '../../../app/router/route_names.dart';
import '../../../app/theme/colors.dart';
import '../../../app/theme/text_styles.dart';
import '../../../core/di/dependency_injection.dart';
import '../../../data/datasources/drift/app_database.dart';
import '../../../features/auth/providers/auth_controller.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/primary_button.dart';

final profileSummaryProvider = FutureProvider.autoDispose<ProfileSummary?>((
  ref,
) async {
  final authRepository = ref.watch(authRepositoryProvider);
  if (authRepository.firebaseUser == null) {
    return null;
  }

  final user = await authRepository.currentLocalUser();
  if (user == null || !user.emailVerified) {
    return null;
  }

  final database = ref.watch(appDatabaseProvider);
  final wishlistCount = await database.countWishlistItems(user.id);
  final addressCount = await database.countAddresses(user.id);
  final cartCount = await database.countCartItems(user.id);

  return ProfileSummary(
    user: user,
    avatarUrl:
        user.avatar ??
        authRepository.firebaseUser?.photoURL ??
        CloudinaryConstants.profileFallbackAvatarUrl,
    wishlistCount: wishlistCount,
    addressCount: addressCount,
    cartCount: cartCount,
  );
});

class ProfileSummary {
  const ProfileSummary({
    required this.user,
    required this.avatarUrl,
    required this.wishlistCount,
    required this.addressCount,
    required this.cartCount,
  });

  final LocalUser user;
  final String avatarUrl;
  final int wishlistCount;
  final int addressCount;
  final int cartCount;
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileSummaryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        bottom: false,
        child: profile.when(
          data: (summary) => summary == null
              ? const _GuestProfileContent()
              : _SignedInProfileContent(summary: summary),
          loading: () => const _ProfileLoadingContent(),
          error: (error, _) => _ProfileErrorContent(message: error.toString()),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(selectedIndex: 4),
    );
  }
}

class _SignedInProfileContent extends ConsumerWidget {
  const _SignedInProfileContent({required this.summary});

  final ProfileSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = summary.user;
    final avatarUrl = summary.avatarUrl;
    final year = user.createdAt.year;
    final createdDate =
        '${user.createdAt.day.toString().padLeft(2, '0')}/'
        '${user.createdAt.month.toString().padLeft(2, '0')}/'
        '${user.createdAt.year}';

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              _ProfileHeader(smallAvatarUrl: avatarUrl),
              const SizedBox(height: 34),
              _MainAvatar(imageUrl: avatarUrl),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  user.fullName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 36,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Thành viên PetJoy từ $year',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: _ProfileInfoPanel(
                  email: user.email,
                  phone: user.phone ?? 'Chưa cập nhật',
                  role: _displayRole(user.role),
                  createdDate: createdDate,
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 110),
          sliver: SliverList.list(
            children: [
              _WideProfileTile(
                icon: Icons.edit_outlined,
                iconColor: AppColors.forest,
                iconBackground: AppColors.leaf,
                title: 'Chỉnh sửa hồ sơ',
                subtitle: 'Cập nhật họ tên, số điện thoại và ảnh đại diện',
                onTap: () => Navigator.pushNamed(
                  context,
                  RouteNames.editProfile,
                  arguments: user,
                ),
              ),
              const SizedBox(height: 18),
              if (user.authProvider == 'email') ...[
                _WideProfileTile(
                  icon: Icons.lock_reset_outlined,
                  iconColor: AppColors.coffee,
                  iconBackground: AppColors.honey,
                  title: 'Đổi mật khẩu',
                  subtitle: 'Bảo mật tài khoản email của bạn',
                  onTap: () =>
                      Navigator.pushNamed(context, RouteNames.changePassword),
                ),
                const SizedBox(height: 18),
              ],
              _WideProfileTile(
                icon: Icons.inventory_2_outlined,
                iconColor: AppColors.coffee,
                iconBackground: AppColors.honey,
                title: 'Lịch sử đơn hàng',
                subtitle: summary.cartCount > 0
                    ? '${summary.cartCount} sản phẩm đang trong giỏ'
                    : 'Theo dõi đơn hàng của bạn',
                onTap: () {},
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _SmallProfileTile(
                      icon: Icons.favorite_border,
                      iconColor: const Color(0xFF5C3329),
                      iconBackground: const Color(0xFFC99A8A),
                      title: 'Yêu thích',
                      subtitle: '${summary.wishlistCount} sản phẩm',
                      onTap: () => Navigator.pushNamed(context, RouteNames.wishlist),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: _SmallProfileTile(
                      icon: Icons.location_on_outlined,
                      iconColor: AppColors.ink,
                      iconBackground: AppColors.leaf,
                      title: 'Địa chỉ đã lưu',
                      subtitle: summary.addressCount > 0
                          ? '${summary.addressCount} địa chỉ'
                          : 'Chưa có địa chỉ',
                      onTap: () async {
                        await Navigator.pushNamed(
                          context,
                          RouteNames.addresses,
                        );
                        ref.invalidate(profileSummaryProvider);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _WideProfileTile(
                icon: Icons.confirmation_num_outlined,
                iconColor: AppColors.coffee,
                iconBackground: AppColors.honey,
                title: 'Mã giảm giá của tôi',
                subtitle: 'Xem các khuyến mãi đang áp dụng',
                onTap: () => Navigator.pushNamed(context, RouteNames.vouchers),
              ),
              const SizedBox(height: 20),
              _WideProfileTile(
                icon: Icons.settings_outlined,
                iconColor: AppColors.muted,
                iconBackground: const Color(0xFFE2E4E2),
                title: 'Cài đặt tài khoản',
                onTap: () {},
              ),
              const SizedBox(height: 18),
              _WideProfileTile(
                icon: Icons.help_outline,
                iconColor: AppColors.muted,
                iconBackground: const Color(0xFFE2E4E2),
                title: 'Trung tâm trợ giúp',
                onTap: () {},
              ),
              const SizedBox(height: 42),
              _LogoutButton(
                onPressed: () async {
                  await ref.read(authControllerProvider.notifier).signOut();
                  ref.invalidate(profileSummaryProvider);
                  if (!context.mounted) {
                    return;
                  }
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    RouteNames.login,
                    (_) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _displayRole(String role) {
    return switch (role.toLowerCase()) {
      'customer' => 'Customer',
      'admin' => 'Admin',
      _ => role,
    };
  }
}

class _ProfileInfoPanel extends StatelessWidget {
  const _ProfileInfoPanel({
    required this.email,
    required this.phone,
    required this.role,
    required this.createdDate,
  });

  final String email;
  final String phone;
  final String role;
  final String createdDate;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          children: [
            _InfoRow(icon: Icons.email_outlined, label: 'Email', value: email),
            const Divider(color: AppColors.line),
            _InfoRow(
              icon: Icons.phone_outlined,
              label: 'Điện thoại',
              value: phone,
            ),
            const Divider(color: AppColors.line),
            _InfoRow(icon: Icons.badge_outlined, label: 'Vai trò', value: role),
            const Divider(color: AppColors.line),
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Ngày tạo',
              value: createdDate,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, color: AppColors.forest, size: 22),
          const SizedBox(width: 12),
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestProfileContent extends StatelessWidget {
  const _GuestProfileContent();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: Column(
            children: [
              _ProfileHeader(),
              SizedBox(height: 40),
              _MainAvatar(
                imageUrl: CloudinaryConstants.profileFallbackAvatarUrl,
              ),
              SizedBox(height: 26),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Bạn chưa đăng nhập',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 34,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              SizedBox(height: 12),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 34),
                child: Text(
                  'Đăng nhập để xem đơn hàng, danh sách yêu thích và địa chỉ đã lưu.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body,
                ),
              ),
              SizedBox(height: 34),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 110),
          sliver: SliverList.list(
            children: [
              PrimaryButton(
                label: 'Đăng nhập',
                icon: Icons.login,
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, RouteNames.login),
              ),
              const SizedBox(height: 20),
              _WideProfileTile(
                icon: Icons.help_outline,
                iconColor: AppColors.muted,
                iconBackground: const Color(0xFFE2E4E2),
                title: 'Trung tâm trợ giúp',
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({this.smallAvatarUrl});

  final String? smallAvatarUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 14),
      color: const Color(0xFFF4F4F4),
      child: Row(
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.menu, size: 30, color: AppColors.forest),
            tooltip: 'Mở menu',
          ),
          const Expanded(
            child: Text(
              'Pet Shop',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.forest,
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _RoundNetworkImage(
            imageUrl:
                smallAvatarUrl ?? CloudinaryConstants.profileFallbackAvatarUrl,
            size: 54,
            borderWidth: 0,
          ),
        ],
      ),
    );
  }
}

class _MainAvatar extends StatelessWidget {
  const _MainAvatar({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _RoundNetworkImage(
          imageUrl: imageUrl,
          size: 150,
          borderColor: AppColors.forest,
          borderWidth: 3,
        ),
        Positioned(
          right: 12,
          bottom: 10,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.forest,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: const Icon(Icons.pets, color: Colors.white, size: 22),
          ),
        ),
      ],
    );
  }
}

class _RoundNetworkImage extends StatelessWidget {
  const _RoundNetworkImage({
    required this.imageUrl,
    required this.size,
    this.borderColor = Colors.transparent,
    this.borderWidth = 0,
  });

  final String imageUrl;
  final double size;
  final Color borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(borderWidth),
      decoration: BoxDecoration(color: borderColor, shape: BoxShape.circle),
      child: ClipOval(
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            color: AppColors.mist,
            child: const Icon(Icons.person, color: AppColors.muted),
          ),
        ),
      ),
    );
  }
}

class _WideProfileTile extends StatelessWidget {
  const _WideProfileTile({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(34),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(34),
        child: Container(
          constraints: const BoxConstraints(minHeight: 86),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              _IconBubble(
                icon: icon,
                iconColor: iconColor,
                backgroundColor: iconBackground,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.muted, size: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallProfileTile extends StatelessWidget {
  const _SmallProfileTile({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          height: 172,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconBubble(
                icon: icon,
                iconColor: iconColor,
                backgroundColor: iconBackground,
                size: 58,
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 19,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    this.size = 66,
  });

  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: Icon(icon, color: iconColor, size: size * 0.48),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 62,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFFFD7D2),
          foregroundColor: const Color(0xFFA30D15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        icon: const Icon(Icons.logout),
        label: const Text('Đăng xuất'),
      ),
    );
  }
}

class _ProfileLoadingContent extends StatelessWidget {
  const _ProfileLoadingContent();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.forest),
    );
  }
}

class _ProfileErrorContent extends StatelessWidget {
  const _ProfileErrorContent({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 42),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.danger),
            ),
          ],
        ),
      ),
    );
  }
}
