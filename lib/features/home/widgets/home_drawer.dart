import 'package:flutter/material.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/colors.dart';

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({super.key});

  static const _items = [
    _DrawerItem(Icons.home_outlined, 'Trang chủ', RouteNames.home),
    _DrawerItem(
      Icons.inventory_2_outlined,
      'Tất cả sản phẩm',
      RouteNames.productList,
    ),
    _DrawerItem(Icons.shopping_cart_outlined, 'Giỏ hàng', RouteNames.cart),
    _DrawerItem(
      Icons.favorite_border,
      'Sản phẩm yêu thích',
      RouteNames.wishlist,
    ),
    _DrawerItem(
      Icons.receipt_long_outlined,
      'Lịch sử đơn hàng',
      RouteNames.orderHistory,
    ),
    _DrawerItem(
      Icons.confirmation_num_outlined,
      'Mã giảm giá',
      RouteNames.vouchers,
    ),
    _DrawerItem(
      Icons.notifications_outlined,
      'Thông báo',
      RouteNames.notifications,
    ),
    _DrawerItem(Icons.person_outline, 'Hồ sơ cá nhân', RouteNames.profile),
  ];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFFAFAFA),
      child: SafeArea(
        child: Column(
          children: [
            const _DrawerHeader(),
            const Divider(height: 1, color: AppColors.line),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 14),
                itemCount: _items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 2),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 22),
                    leading: Icon(item.icon, color: AppColors.forest),
                    title: Text(
                      item.label,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppColors.muted,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    onTap: () => _openRoute(context, item.route),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openRoute(BuildContext context, String route) {
    final navigator = Navigator.of(context);
    final currentRoute = ModalRoute.of(context)?.settings.name;
    navigator.pop();

    if (currentRoute != route) {
      navigator.pushNamed(route);
    }
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(22, 22, 22, 20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 27,
            backgroundColor: AppColors.honey,
            child: Icon(Icons.pets, color: AppColors.forest, size: 30),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PetJoy',
                  style: TextStyle(
                    color: AppColors.forest,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Mua sắm cho thú cưng',
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem {
  const _DrawerItem(this.icon, this.label, this.route);

  final IconData icon;
  final String label;
  final String route;
}
