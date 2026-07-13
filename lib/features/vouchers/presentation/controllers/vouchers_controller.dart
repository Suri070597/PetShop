import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../data/datasources/drift/app_database.dart';

/// Provider to fetch all active vouchers.
final vouchersProvider = FutureProvider.autoDispose<List<Voucher>>((ref) {
  return ref.watch(vouchersRepositoryProvider).getVouchers();
});

/// State notifier or class for voucher operations.
class VouchersController {
  final Ref _ref;

  VouchersController(this._ref);

  /// Apply a voucher code.
  Future<Voucher> applyVoucher(String code, double orderValue) async {
    final repo = _ref.read(vouchersRepositoryProvider);
    return await repo.applyVoucher(code, orderValue);
  }
}

final vouchersControllerProvider = Provider<VouchersController>((ref) {
  return VouchersController(ref);
});
