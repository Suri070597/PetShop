import 'package:flutter/material.dart';

import '../../app/router/route_names.dart';
import '../../app/theme/colors.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.selectedIndex, this.onTap});

  final int selectedIndex;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(Icons.home_outlined, 'Trang chủ', RouteNames.home),
      _NavItem(Icons.category_outlined, 'Danh mục', RouteNames.productList),
      _NavItem(Icons.shopping_cart_outlined, 'Giỏ hàng', RouteNames.cart),
      _NavItem(Icons.favorite_border, 'Yêu thích', RouteNames.wishlist),
      _NavItem(Icons.person_outline, 'Hồ sơ', RouteNames.profile),
    ];

    return Container(
      height: 88,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEF),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(items.length, (index) {
          final isSelected = index == selectedIndex;
          final item = items[index];

          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () {
                onTap?.call(index);
                if (item.route == null || isSelected) {
                  return;
                }
                Navigator.pushReplacementNamed(context, item.route!);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 58,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.honey : Colors.transparent,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          item.icon,
                          color: isSelected
                              ? AppColors.coffee
                              : AppColors.muted,
                        ),
                        if (index == 2)
                          const Positioned(
                            right: -4,
                            top: -4,
                            child: SizedBox.square(
                              dimension: 8,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: AppColors.danger,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected ? AppColors.coffee : AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.label, this.route);

  final IconData icon;
  final String label;
  final String? route;
}
