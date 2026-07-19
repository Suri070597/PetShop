import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../domain/order_models.dart';

abstract final class OrderStatusHelper {
  static const progressStatuses = [
    'Pending',
    'Confirmed',
    'Preparing',
    'Shipping',
    'Delivered',
  ];

  static String label(String status) {
    switch (status) {
      case 'Pending':
        return 'Chờ xác nhận';
      case 'Confirmed':
        return 'Đã xác nhận';
      case 'Preparing':
        return 'Đang chuẩn bị hàng';
      case 'Shipping':
        return 'Đang giao hàng';
      case 'Delivered':
        return 'Đã giao hàng';
      case 'Cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  static Color color(String status) {
    switch (status) {
      case 'Delivered':
        return AppColors.forest;
      case 'Cancelled':
        return AppColors.danger;
      case 'Shipping':
        return Colors.blue;
      case 'Preparing':
        return Colors.deepOrange;
      case 'Confirmed':
        return Colors.teal;
      case 'Pending':
      default:
        return AppColors.coffee;
    }
  }

  static bool canCancel(String status) {
    return status == 'Pending' || status == 'Confirmed';
  }

  static int progressIndex(String status) {
    final index = progressStatuses.indexOf(status);
    return index < 0 ? 0 : index;
  }

  static String paymentLabel(String status) {
    switch (status) {
      case 'Paid':
        return 'Đã thanh toán';
      case 'Refunded':
        return 'Đã hoàn tiền';
      case 'Cancelled':
        return 'Đã hủy thanh toán';
      case 'Pending':
      default:
        return 'Chưa thanh toán';
    }
  }

  static String paymentMethodLabel(String code) {
    return PaymentMethodCodes.label(code);
  }
}
