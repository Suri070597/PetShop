import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_shop/app/app.dart';
import 'package:pet_shop/core/di/dependency_injection.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('PetJoy app renders splash then home', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: const PetShopApp(),
      ),
    );

    expect(find.text('PetJoy'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.text('Pet Shop Hoàn Hảo'), findsOneWidget);
  });
}
