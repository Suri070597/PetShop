import 'package:intl/intl.dart';

abstract final class MoneyFormatter {
  static final _vnd = NumberFormat.decimalPattern('vi_VN');

  /// Hiển thị giá catalog cũ theo quy ước 1 đơn vị = 1.000 VND.
  /// Chỉ đổi cách hiển thị; dữ liệu và phép tính vẫn dùng giá trị gốc.
  static String vndFromLegacy(double value) {
    return '${_vnd.format(value * 1000)} VND';
  }
}
