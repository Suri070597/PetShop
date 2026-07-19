import '../../../data/datasources/drift/app_database.dart' as drift_db;

/// Các mã phương thức thanh toán được lưu trực tiếp vào cột
/// `Orders.paymentMethod` trong SQLite.
abstract final class PaymentMethodCodes {
  static const cod = 'COD';
  static const bankTransfer = 'BankTransfer';

  static String label(String code) {
    switch (code) {
      case bankTransfer:
        return 'Chuyển khoản ngân hàng';
      case cod:
      default:
        return 'Thanh toán khi nhận hàng';
    }
  }

  /// Bản demo xem chuyển khoản là đã thanh toán thành công.
  /// COD chỉ được thanh toán khi khách nhận hàng.
  static String initialPaymentStatus(String code) {
    return code == bankTransfer ? 'Paid' : 'Pending';
  }
}

/// Dữ liệu địa chỉ nhận hàng do màn hình Checkout gửi xuống repository.
class CheckoutAddressInput {
  const CheckoutAddressInput({
    this.addressId,
    required this.receiverName,
    required this.phone,
    required this.province,
    required this.district,
    required this.ward,
    required this.street,
  });

  final int? addressId;
  final String receiverName;
  final String phone;
  final String province;
  final String district;
  final String ward;
  final String street;
}

/// Một sản phẩm hiển thị trong chi tiết đơn hàng.
class OrderProductLine {
  const OrderProductLine({
    required this.orderDetailId,
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.quantity,
    required this.price,
    required this.subTotal,
  });

  final int orderDetailId;
  final int productId;
  final String productName;
  final String imageUrl;
  final int quantity;
  final double price;
  final double subTotal;
}

/// Toàn bộ dữ liệu cần cho màn hình Order Detail.
class OrderDetailViewData {
  const OrderDetailViewData({
    required this.order,
    required this.address,
    required this.lines,
  });

  final drift_db.Order order;
  final drift_db.AddressesData address;
  final List<OrderProductLine> lines;

  double get subTotal => lines.fold<double>(
        0.0,
        (sum, line) => sum + line.subTotal,
      );
}

/// Kết quả khi người dùng bấm "Mua lại".
class ReorderResult {
  const ReorderResult({
    required this.addedQuantity,
    required this.warnings,
  });

  final int addedQuantity;
  final List<String> warnings;

  bool get hasWarnings => warnings.isNotEmpty;
}
