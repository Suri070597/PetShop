import 'package:intl/intl.dart';

abstract final class MoneyFormatter {
  static final _usd = NumberFormat.currency(locale: 'en_US', symbol: r'$');

  static String usd(double value) => _usd.format(value);
}
