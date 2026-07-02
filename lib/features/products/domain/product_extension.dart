//=============================================
//dữ liệu categoryName ĐẶC BIỆT KHÔNG CÓ TRONG API, nên cần tạo một getter để lấy categoryName từ categoryId.
//class để đổi màu sắc
//=============================================

import 'package:flutter/material.dart';
// Đảm bảo import đúng file chứa class Product của Drift đang dùng
import '../../../data/datasources/drift/app_database.dart';

extension ProductColorX on Product {
  // Tự động thêm getter categoryName vào class Product của Drift
  String get categoryName {
    switch (categoryId) {
      case 1: return 'Thức ăn';
      case 2: return 'Phụ kiện';
      case 3: return 'Đồ chơi';
      case 4: return 'Sức khỏe';
      default: return 'Khác';
    }
  }

  // Tự động thêm getter categoryColor vào class Product của Drift
  Color get categoryColor {
    switch (categoryId) {
      case 1: 
        return const Color.fromARGB(255, 124, 151, 27); // Xanh lá cây
      case 2:
        return const Color(0xFF1565C0); // Xanh dương
      case 3: 
        return const Color.fromARGB(255, 255, 0, 0); // Màu nâu
      default: 
        return const Color(0xFF212121); // Màu đen/xám
    }
  }
}