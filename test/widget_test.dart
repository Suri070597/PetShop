import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_shop/app/app.dart';
import 'package:pet_shop/core/di/dependency_injection.dart';
import 'package:pet_shop/data/datasources/drift/app_database.dart';
import 'package:pet_shop/features/auth/providers/auth_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('PetJoy app renders splash then login', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          authControllerProvider.overrideWith(
            (ref) => _FakeAuthController(ref),
          ),
        ],
        child: const PetShopApp(),
      ),
    );

    expect(find.text('PetJoy'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Chào mừng trở lại!'), findsOneWidget);
  });
}

class _FakeAuthController extends AuthController {
  _FakeAuthController(super.ref);

  @override
  Future<LocalUser?> restoreSession() async => null;
}
