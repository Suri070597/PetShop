import 'package:drift/drift.dart';
import '../datasources/drift/app_database.dart';
import '../../core/errors/exceptions.dart';

class VouchersRepository {
  final AppDatabase _database;

  VouchersRepository(this._database);

  /// Fetch all active and available vouchers.
  Future<List<Voucher>> getVouchers() async {
    final now = DateTime.now();
    final query = _database.select(_database.vouchers)
      ..where((t) => t.status.equals(true))
      ..where((t) => t.startDate.isSmallerOrEqualValue(now))
      ..where((t) => t.endDate.isBiggerOrEqualValue(now))
      ..where((t) => t.quantity.isBiggerThan(t.usedCount));
    
    return query.get();
  }

  /// Validate and apply a voucher by code.
  Future<Voucher> applyVoucher(String code, double orderValue) async {
    final now = DateTime.now();
    final voucher = await (_database.select(_database.vouchers)
          ..where((t) => t.code.equals(code.trim().toUpperCase())))
        .getSingleOrNull();

    if (voucher == null) {
      throw const AppException('Mã giảm giá không tồn tại.');
    }

    if (!voucher.status) {
      throw const AppException('Mã giảm giá đã bị vô hiệu hóa.');
    }

    if (voucher.startDate.isAfter(now)) {
      throw const AppException('Mã giảm giá chưa đến hạn sử dụng.');
    }

    if (voucher.endDate.isBefore(now)) {
      throw const AppException('Mã giảm giá đã hết hạn sử dụng.');
    }

    if (voucher.usedCount >= voucher.quantity) {
      throw const AppException('Mã giảm giá đã hết lượt sử dụng.');
    }

    if (orderValue < voucher.minOrderValue) {
      throw AppException(
        'Đơn hàng chưa đạt giá trị tối thiểu để áp dụng mã này (Tối thiểu $minOrderValueUSD).',
      );
    }

    return voucher;
  }
  
  // Format price helper
  String get minOrderValueUSD => '\$${_database.vouchers.minOrderValue.toString()}';
}
