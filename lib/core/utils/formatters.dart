import 'package:intl/intl.dart';

abstract final class MoneyFormatter {
  static final _usd = NumberFormat.currency(locale: 'en_US', symbol: r'$');
  static final _vnd = NumberFormat.decimalPattern('vi_VN');

  static String usd(double value) => _usd.format(value);

  /// Hiển thị giá catalog cũ theo quy ước 1 đơn vị = 1.000 VND.
  /// Luồng thanh toán vẫn dùng dữ liệu gốc cho đến khi được migration riêng.
  static String vndFromLegacy(double value) {
    return '${_vnd.format(value * 1000)} VND';
  }
}
