import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../app/constants/app_constants.dart';
import '../../../app/constants/cloudinary_constants.dart';

part 'app_database.g.dart';

class LocalUsers extends Table {
  TextColumn get id => text()();
  TextColumn get fullName => text().withLength(min: 1, max: 100)();
  TextColumn get email => text().withLength(min: 3, max: 100).unique()();
  TextColumn get phone => text().withLength(max: 20).nullable()();
  TextColumn get avatar => text().withLength(max: 255).nullable()();
  TextColumn get passwordHash => text().nullable()();
  TextColumn get authProvider => text().withDefault(const Constant('email'))();
  TextColumn get role => text().withDefault(const Constant('customer'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get emailVerified =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get status => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Addresses extends Table {
  IntColumn get addressId => integer().autoIncrement()();
  TextColumn get userId => text().references(LocalUsers, #id)();
  TextColumn get receiverName => text().withLength(max: 100)();
  TextColumn get phone => text().withLength(max: 20)();
  TextColumn get province => text().withLength(max: 100)();
  TextColumn get district => text().withLength(max: 100)();
  TextColumn get ward => text().withLength(max: 100)();
  TextColumn get street => text().withLength(max: 255)();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
}

class Categories extends Table {
  IntColumn get categoryId => integer().autoIncrement()();
  TextColumn get categoryName => text().withLength(max: 100)();
  TextColumn get description => text().withLength(max: 255).nullable()();
  TextColumn get imageUrl => text().withLength(max: 255).nullable()();
}

class Products extends Table {
  IntColumn get productId => integer().autoIncrement()();
  IntColumn get categoryId => integer().references(Categories, #categoryId)();
  TextColumn get productName => text().withLength(max: 200)();
  TextColumn get description => text()();
  RealColumn get price => real()();
  RealColumn get discountPrice => real().nullable()();
  IntColumn get stockQuantity => integer().withDefault(const Constant(0))();
  RealColumn get weight => real().nullable()();
  TextColumn get brand => text().withLength(max: 100).nullable()();
  TextColumn get thumbnail => text().withLength(max: 255).nullable()();
  RealColumn get averageRating => real().withDefault(const Constant(0))();
  IntColumn get reviewCount => integer().withDefault(const Constant(0))();
  BoolColumn get isFeatured => boolean().withDefault(const Constant(false))();
  BoolColumn get status => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class ProductImages extends Table {
  IntColumn get imageId => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #productId)();
  TextColumn get imageUrl => text().withLength(max: 255)();
}

class CartItems extends Table {
  IntColumn get cartItemId => integer().autoIncrement()();
  TextColumn get userId => text().references(LocalUsers, #id)();
  IntColumn get productId => integer().references(Products, #productId)();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  RealColumn get unitPrice => real()();
}

class Orders extends Table {
  IntColumn get orderId => integer().autoIncrement()();
  TextColumn get userId => text().references(LocalUsers, #id)();
  IntColumn get addressId => integer().references(Addresses, #addressId)();
  IntColumn get voucherId =>
      integer().nullable().references(Vouchers, #voucherId)();
  DateTimeColumn get orderDate => dateTime().withDefault(currentDateAndTime)();
  RealColumn get totalAmount => real()();
  RealColumn get shippingFee => real().withDefault(const Constant(0))();
  RealColumn get discountAmount => real().withDefault(const Constant(0))();
  TextColumn get paymentMethod => text().withDefault(const Constant('COD'))();
  TextColumn get paymentStatus =>
      text().withDefault(const Constant('Pending'))();
  TextColumn get orderStatus => text().withDefault(const Constant('Pending'))();
}

class OrderDetails extends Table {
  IntColumn get orderDetailId => integer().autoIncrement()();
  IntColumn get orderId => integer().references(Orders, #orderId)();
  IntColumn get productId => integer().references(Products, #productId)();
  IntColumn get quantity => integer()();
  RealColumn get price => real()();
  RealColumn get subTotal => real()();
}

class Reviews extends Table {
  IntColumn get reviewId => integer().autoIncrement()();
  TextColumn get userId => text().references(LocalUsers, #id)();
  IntColumn get productId => integer().references(Products, #productId)();
  IntColumn get rating => integer()();
  TextColumn get comment => text().withLength(max: 1000).nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Wishlist extends Table {
  IntColumn get wishlistId => integer().autoIncrement()();
  TextColumn get userId => text().references(LocalUsers, #id)();
  IntColumn get productId => integer().references(Products, #productId)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Vouchers extends Table {
  IntColumn get voucherId => integer().autoIncrement()();
  TextColumn get code => text().withLength(max: 50).unique()();
  TextColumn get voucherName => text().withLength(max: 100)();
  IntColumn get discountPercent => integer()();
  RealColumn get maxDiscount => real()();
  RealColumn get minOrderValue => real()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  IntColumn get quantity => integer()();
  IntColumn get usedCount => integer().withDefault(const Constant(0))();
  BoolColumn get status => boolean().withDefault(const Constant(true))();
}

class Notifications extends Table {
  IntColumn get notificationId => integer().autoIncrement()();
  TextColumn get userId => text().references(LocalUsers, #id)();
  TextColumn get title => text().withLength(max: 100)();
  TextColumn get content => text().withLength(max: 500)();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(
  tables: [
    LocalUsers,
    Addresses,
    Categories,
    Products,
    ProductImages,
    CartItems,
    Orders,
    OrderDetails,
    Reviews,
    Wishlist,
    Vouchers,
    Notifications,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await customStatement('DROP TABLE IF EXISTS email_verification_codes');
      }
    },
  );

  Future<LocalUser?> findUserById(String id) {
    return (select(
      localUsers,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
  }

  Future<LocalUser?> findUserByEmail(String email) {
    return (select(
      localUsers,
    )..where((table) => table.email.equals(email))).getSingleOrNull();
  }

  Future<int> countWishlistItems(String userId) {
    return (selectOnly(wishlist)
          ..addColumns([wishlist.wishlistId.count()])
          ..where(wishlist.userId.equals(userId)))
        .map((row) => row.read(wishlist.wishlistId.count()) ?? 0)
        .getSingle();
  }

  Future<int> countAddresses(String userId) {
    return (selectOnly(addresses)
          ..addColumns([addresses.addressId.count()])
          ..where(addresses.userId.equals(userId)))
        .map((row) => row.read(addresses.addressId.count()) ?? 0)
        .getSingle();
  }

  Future<int> countCartItems(String userId) {
    return (selectOnly(cartItems)
          ..addColumns([cartItems.cartItemId.count()])
          ..where(cartItems.userId.equals(userId)))
        .map((row) => row.read(cartItems.cartItemId.count()) ?? 0)
        .getSingle();
  }

  Future<void> upsertUser(LocalUsersCompanion user) {
    return into(localUsers).insertOnConflictUpdate(user);
  }

  Future<void> updateUserProfile({
    required String userId,
    required String fullName,
    required String phone,
    String? avatar,
  }) {
    return (update(
      localUsers,
    )..where((table) => table.id.equals(userId))).write(
      LocalUsersCompanion(
        fullName: Value(fullName),
        phone: Value(phone),
        avatar: avatar == null ? const Value.absent() : Value(avatar),
      ),
    );
  }

  Future<int> updateUserPasswordHash({
    required String userId,
    required String passwordHash,
  }) {
    return (update(localUsers)..where((table) => table.id.equals(userId)))
        .write(LocalUsersCompanion(passwordHash: Value(passwordHash)));
  }

  Future<void> setUserEmailVerified(String userId, bool value) {
    return (update(localUsers)..where((table) => table.id.equals(userId)))
        .write(LocalUsersCompanion(emailVerified: Value(value)));
  }

  Future<void> seedCatalog() async {
    final count =
        await (selectOnly(categories)
              ..addColumns([categories.categoryId.count()]))
            .map((row) => row.read(categories.categoryId.count()) ?? 0)
            .getSingle();
    if (count == 0) {
      await batch((batch) {
        batch.insertAll(categories, [
          const CategoriesCompanion(
            categoryId: Value(1),
            categoryName: Value('Thức ăn'),
            description: Value('Thức ăn khô và pate cho thú cưng'),
          ),
          const CategoriesCompanion(
            categoryId: Value(2),
            categoryName: Value('Phụ kiện'),
            description: Value('Vòng cổ, dây dắt và túi vận chuyển'),
          ),
          const CategoriesCompanion(
            categoryId: Value(3),
            categoryName: Value('Đồ chơi'),
            description: Value('Đồ chơi giúp thú cưng vận động mỗi ngày'),
          ),
          const CategoriesCompanion(
            categoryId: Value(4),
            categoryName: Value('Sức khỏe'),
            description: Value('Chăm sóc sức khỏe và vệ sinh'),
          ),
        ]);
      });
    }

    final productList = [
      // --- DANH MỤC 1: THỨC ĂN ---
      ProductsCompanion(
        productId: const Value(1),
        categoryId: const Value(1),
        productName: const Value('Hạt hữu cơ không ngũ cốc'),
        description: const Value(
          'Công thức giàu đạm, phù hợp cho chó mèo nhạy cảm với ngũ cốc.',
        ),
        price: const Value(24.99),
        stockQuantity: const Value(42),
        weight: const Value(1.5),
        brand: const Value('Paw & Bag'),
        thumbnail: const Value(CloudinaryConstants.productKibbleUrl),
        averageRating: const Value(0.0),
        reviewCount: const Value(0),
        isFeatured: const Value(true),
        createdAt: Value(DateTime.now()),
      ),
      ProductsCompanion(
        productId: const Value(3),
        categoryId: const Value(1),
        productName: const Value('Pate Mèo Cá Hồi & Rau Củ (12 lon)'),
        description: const Value(
          'Pate thơm ngon bổ dưỡng, bổ sung Omega-3 cho bộ lông óng mượt.',
        ),
        price: const Value(18.50),
        stockQuantity: const Value(50),
        weight: const Value(1.2),
        brand: const Value('Whiskas'),
        thumbnail: const Value(
          'https://images.unsplash.com/photo-1589924691995-400dc9ecc119?w=600&auto=format&fit=crop',
        ),
        averageRating: const Value(0.0),
        reviewCount: const Value(0),
        isFeatured: const Value(true),
        createdAt: Value(DateTime.now()),
      ),
      ProductsCompanion(
        productId: const Value(4),
        categoryId: const Value(1),
        productName: const Value('Hạt Chó Trưởng Thành Vị Bò & Rau Củ'),
        description: const Value(
          'Cung cấp đầy đủ năng lượng và dưỡng chất cho cún cưng năng động.',
        ),
        price: const Value(32.00),
        stockQuantity: const Value(35),
        weight: const Value(3.0),
        brand: const Value('Royal Canin'),
        thumbnail: const Value(
          'https://images.unsplash.com/photo-1568640347023-a616a30bc3bd?w=600&auto=format&fit=crop',
        ),
        averageRating: const Value(0.0),
        reviewCount: const Value(0),
        isFeatured: const Value(true),
        createdAt: Value(DateTime.now()),
      ),
      ProductsCompanion(
        productId: const Value(5),
        categoryId: const Value(1),
        productName: const Value('Súp Thưởng Cho Mèo Ciao Churu (20 thanh)'),
        description: const Value(
          'Món ăn khoái khẩu của các hoàng thượng, bổ sung nước và vitamin.',
        ),
        price: const Value(9.99),
        stockQuantity: const Value(100),
        weight: const Value(0.3),
        brand: const Value('Ciao Churu'),
        thumbnail: const Value(
          'https://images.unsplash.com/photo-1548767797-d8c844163c4c?w=600&auto=format&fit=crop',
        ),
        averageRating: const Value(0.0),
        reviewCount: const Value(0),
        isFeatured: const Value(true),
        createdAt: Value(DateTime.now()),
      ),

      // --- DANH MỤC 2: PHỤ KIỆN ---
      ProductsCompanion(
        productId: const Value(6),
        categoryId: const Value(2),
        productName: const Value('Vòng Cổ Da Cao Cấp Có Chuông'),
        description: const Value(
          'Chất liệu da mềm mại, bền đẹp, không làm đau cổ thú cưng.',
        ),
        price: const Value(8.99),
        stockQuantity: const Value(80),
        brand: const Value('PetJoy'),
        thumbnail: const Value(
          'https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=600&auto=format&fit=crop',
        ),
        averageRating: const Value(0.0),
        reviewCount: const Value(0),
        isFeatured: const Value(true),
        createdAt: Value(DateTime.now()),
      ),
      ProductsCompanion(
        productId: const Value(7),
        categoryId: const Value(2),
        productName: const Value('Dây Dắt Yếm Ngực Chống Giật'),
        description: const Value(
          'Thiết kế ôm sát ngực, phân bổ lực đều giúp dạo phố an toàn.',
        ),
        price: const Value(15.99),
        stockQuantity: const Value(45),
        brand: const Value('ToughPup'),
        thumbnail: const Value(
          'https://images.unsplash.com/photo-1535294435445-d7249524ef2e?w=600&auto=format&fit=crop',
        ),
        averageRating: const Value(0.0),
        reviewCount: const Value(0),
        isFeatured: const Value(true),
        createdAt: Value(DateTime.now()),
      ),
      ProductsCompanion(
        productId: const Value(8),
        categoryId: const Value(2),
        productName: const Value('Balo Vận Chuyển Trong Suốt'),
        description: const Value(
          'Balo phi hành gia thông thoáng, dễ dàng quan sát thế giới bên ngoài.',
        ),
        price: const Value(29.90),
        stockQuantity: const Value(30),
        brand: const Value('SpacePet'),
        thumbnail: const Value(
          'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=600&auto=format&fit=crop',
        ),
        averageRating: const Value(0.0),
        reviewCount: const Value(0),
        isFeatured: const Value(true),
        createdAt: Value(DateTime.now()),
      ),
      ProductsCompanion(
        productId: const Value(9),
        categoryId: const Value(2),
        productName: const Value('Bát Ăn Đôi Inox Chống Trượt'),
        description: const Value(
          'Khay nhựa cao cấp kết hợp 2 bát inox tháo rời dễ vệ sinh.',
        ),
        price: const Value(11.50),
        stockQuantity: const Value(60),
        brand: const Value('PetJoy'),
        thumbnail: const Value(
          'https://images.unsplash.com/photo-1541781774459-bb2af2f05b55?w=600&auto=format&fit=crop',
        ),
        averageRating: const Value(0.0),
        reviewCount: const Value(0),
        isFeatured: const Value(false),
        createdAt: Value(DateTime.now()),
      ),

      // --- DANH MỤC 3: ĐỒ CHƠI ---
      ProductsCompanion(
        productId: const Value(2),
        categoryId: const Value(3),
        productName: const Value('Cần câu lông sắc màu'),
        description: const Value(
          'Đồ chơi tương tác giúp mèo giải tỏa năng lượng và gắn kết với chủ.',
        ),
        price: const Value(12.50),
        stockQuantity: const Value(68),
        brand: const Value('PetJoy'),
        thumbnail: const Value(CloudinaryConstants.productFeatherWandUrl),
        averageRating: const Value(0.0),
        reviewCount: const Value(0),
        isFeatured: const Value(true),
        createdAt: Value(DateTime.now()),
      ),
      ProductsCompanion(
        productId: const Value(10),
        categoryId: const Value(3),
        productName: const Value('Bóng Cao Su Gai Nhai Sạch Răng'),
        description: const Value(
          'Giúp chó làm sạch mảng bám trên răng và giải trí mỗi ngày.',
        ),
        price: const Value(6.50),
        stockQuantity: const Value(90),
        brand: const Value('ChewMaster'),
        thumbnail: const Value(
          'https://images.unsplash.com/photo-1576201836106-db1758fd1c97?w=600&auto=format&fit=crop',
        ),
        averageRating: const Value(0.0),
        reviewCount: const Value(0),
        isFeatured: const Value(false),
        createdAt: Value(DateTime.now()),
      ),
      ProductsCompanion(
        productId: const Value(11),
        categoryId: const Value(3),
        productName: const Value('Tháp Đồ Chơi 3 Tầng Cho Mèo'),
        description: const Value(
          'Tháp bóng lăn xoay tròn kích thích bản năng săn mồi của mèo.',
        ),
        price: const Value(14.99),
        stockQuantity: const Value(40),
        brand: const Value('CatFun'),
        thumbnail: const Value(
          'https://images.unsplash.com/photo-1545249390-6bdfa286032f?w=600&auto=format&fit=crop',
        ),
        averageRating: const Value(0.0),
        reviewCount: const Value(0),
        isFeatured: const Value(true),
        createdAt: Value(DateTime.now()),
      ),
      ProductsCompanion(
        productId: const Value(12),
        categoryId: const Value(3),
        productName: const Value('Cào Móng Carton Hình Gợn Sóng'),
        description: const Value(
          'Bàn cào móng bền bỉ, giúp mèo bảo vệ móng và đồ đạc trong nhà.',
        ),
        price: const Value(9.50),
        stockQuantity: const Value(55),
        brand: const Value('PetJoy'),
        thumbnail: const Value(
          'https://images.unsplash.com/photo-1533738363-b7f9aef128ce?w=600&auto=format&fit=crop',
        ),
        averageRating: const Value(0.0),
        reviewCount: const Value(0),
        isFeatured: const Value(false),
        createdAt: Value(DateTime.now()),
      ),

      // --- DANH MỤC 4: SỨC KHỎE ---
      ProductsCompanion(
        productId: const Value(13),
        categoryId: const Value(4),
        productName: const Value('Sữa Tắm Dưỡng Lông Khử Mùi (500ml)'),
        description: const Value(
          'Chiết xuất tự nhiên, làm sạch dịu nhẹ và lưu hương thơm lâu dài.',
        ),
        price: const Value(16.99),
        stockQuantity: const Value(50),
        brand: const Value('Bio-Clean'),
        thumbnail: const Value(
          'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?w=600&auto=format&fit=crop',
        ),
        averageRating: const Value(0.0),
        reviewCount: const Value(0),
        isFeatured: const Value(true),
        createdAt: Value(DateTime.now()),
      ),
      ProductsCompanion(
        productId: const Value(14),
        categoryId: const Value(4),
        productName: const Value('Dung Dịch Nhỏ Tai Trị Rận & Nấm'),
        description: const Value(
          'Vệ sinh tai, ngăn ngừa rận tai và ngứa ngáy hiệu quả.',
        ),
        price: const Value(10.99),
        stockQuantity: const Value(65),
        brand: const Value('VetHealth'),
        thumbnail: const Value(
          'https://images.unsplash.com/photo-1628009368231-7bb7cfcb0def?w=600&auto=format&fit=crop',
        ),
        averageRating: const Value(0.0),
        reviewCount: const Value(0),
        isFeatured: const Value(false),
        createdAt: Value(DateTime.now()),
      ),
      ProductsCompanion(
        productId: const Value(15),
        categoryId: const Value(4),
        productName: const Value('Gel Dinh Dưỡng Bổ Sung Vitamin'),
        description: const Value(
          'Cung cấp năng lượng tức thì và vitamin thiết yếu cho thú cưng còi cọc.',
        ),
        price: const Value(13.50),
        stockQuantity: const Value(42),
        brand: const Value('NutriPet'),
        thumbnail: const Value(
          'https://images.unsplash.com/photo-1623387641168-d9803ddd3f35?w=600&auto=format&fit=crop',
        ),
        averageRating: const Value(0.0),
        reviewCount: const Value(0),
        isFeatured: const Value(true),
        createdAt: Value(DateTime.now()),
      ),
      ProductsCompanion(
        productId: const Value(16),
        categoryId: const Value(4),
        productName: const Value('Kìm Cắt Móng Chó Mèo Kèm Đèn LED'),
        description: const Value(
          'Đèn LED chiếu sáng giúp cắt móng an toàn, không phạm vào mạch máu.',
        ),
        price: const Value(7.99),
        stockQuantity: const Value(75),
        brand: const Value('PetJoy'),
        thumbnail: const Value(
          'https://images.unsplash.com/photo-1517451330947-7809dead78d5?w=600&auto=format&fit=crop',
        ),
        averageRating: const Value(0.0),
        reviewCount: const Value(0),
        isFeatured: const Value(false),
        createdAt: Value(DateTime.now()),
      ),
    ];

    for (final p in productList) {
      await into(products).insert(p, mode: InsertMode.insertOrIgnore);
    }

    await batch((b) {
      // Seed Vouchers
      b.insertAll(vouchers, [
        VouchersCompanion(
          code: const Value('PETJOYNEW'),
          voucherName: const Value('Quà tặng thành viên mới'),
          discountPercent: const Value(15),
          maxDiscount: const Value(10.0),
          minOrderValue: const Value(20.0),
          startDate: Value(DateTime.now().subtract(const Duration(days: 5))),
          endDate: Value(DateTime.now().add(const Duration(days: 30))),
          quantity: const Value(100),
          usedCount: const Value(0),
          status: const Value(true),
        ),
        VouchersCompanion(
          code: const Value('FREESHIP'),
          voucherName: const Value('Miễn phí vận chuyển'),
          discountPercent: const Value(100),
          maxDiscount: const Value(5.0),
          minOrderValue: const Value(15.0),
          startDate: Value(DateTime.now().subtract(const Duration(days: 5))),
          endDate: Value(DateTime.now().add(const Duration(days: 30))),
          quantity: const Value(500),
          usedCount: const Value(0),
          status: const Value(true),
        ),
        VouchersCompanion(
          code: const Value('PETLOVE'),
          voucherName: const Value('Tri ân khách hàng yêu thú cưng'),
          discountPercent: const Value(20),
          maxDiscount: const Value(15.0),
          minOrderValue: const Value(50.0),
          startDate: Value(DateTime.now().subtract(const Duration(days: 1))),
          endDate: Value(DateTime.now().add(const Duration(days: 15))),
          quantity: const Value(50),
          usedCount: const Value(0),
          status: const Value(true),
        ),
      ], mode: InsertMode.insertOrIgnore);
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, AppConstants.databaseName));
    return NativeDatabase.createInBackground(file);
  });
}
