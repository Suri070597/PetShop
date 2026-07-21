import 'package:flutter_test/flutter_test.dart';
import 'package:pet_shop/core/utils/formatters.dart';

void main() {
  test('formats legacy catalog prices as Vietnamese dong', () {
    expect(MoneyFormatter.vndFromLegacy(18.50), '18.500 VND');
    expect(MoneyFormatter.vndFromLegacy(24.99), '24.990 VND');
    expect(MoneyFormatter.vndFromLegacy(50), '50.000 VND');
  });
}
