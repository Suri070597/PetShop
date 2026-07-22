import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_shop/app/app.dart';
import 'package:pet_shop/app/router/route_names.dart';
import 'package:pet_shop/core/di/dependency_injection.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('đăng ký đầy đủ route checkout và phương thức thanh toán', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: const PetShopApp(),
      ),
    );

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.routes, contains(RouteNames.checkout));

    final paymentRoute = app.onGenerateRoute?.call(
      const RouteSettings(
        name: RouteNames.paymentMethod,
        arguments: 'BANK_TRANSFER',
      ),
    );
    expect(paymentRoute, isNotNull);
    expect(paymentRoute?.settings.name, RouteNames.paymentMethod);
  });
}
