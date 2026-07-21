import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_shop/app/router/route_names.dart';
import 'package:pet_shop/features/home/widgets/home_drawer.dart';

void main() {
  const destinations = <String, String>{
    'Tất cả sản phẩm': RouteNames.productList,
    'Giỏ hàng': RouteNames.cart,
    'Sản phẩm yêu thích': RouteNames.wishlist,
    'Lịch sử đơn hàng': RouteNames.orderHistory,
    'Mã giảm giá': RouteNames.vouchers,
    'Thông báo': RouteNames.notifications,
    'Hồ sơ cá nhân': RouteNames.profile,
  };

  for (final entry in destinations.entries) {
    testWidgets('${entry.key} mở trang mới và có thể quay lại Home', (
      tester,
    ) async {
      final homeKey = GlobalKey<ScaffoldState>();

      await tester.pumpWidget(
        MaterialApp(
          initialRoute: RouteNames.home,
          routes: {
            RouteNames.home: (_) => Scaffold(
              key: homeKey,
              appBar: AppBar(title: const Text('Home test')),
              drawer: const HomeDrawer(),
            ),
            for (final route in destinations.values)
              route: (_) =>
                  Scaffold(appBar: AppBar(title: Text('Đích $route'))),
          },
        ),
      );

      homeKey.currentState!.openDrawer();
      await tester.pumpAndSettle();
      if (entry.key == 'Hồ sơ cá nhân') {
        await tester.drag(find.byType(ListView), const Offset(0, -120));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text(entry.key));
      await tester.pumpAndSettle();

      expect(find.text('Đích ${entry.value}'), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Home test'), findsOneWidget);
    });
  }
}
