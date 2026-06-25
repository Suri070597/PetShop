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
  AppDatabase() : super(_openConnection());

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

  Future<void> upsertUser(LocalUsersCompanion user) {
    return into(localUsers).insertOnConflictUpdate(user);
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
    if (count > 0) {
      return;
    }

    await batch((batch) {
      batch.insertAll(categories, [
        const CategoriesCompanion(
          categoryId: Value(1),
          categoryName: Value('Thuc an'),
          description: Value('Thuc an kho va pate cho thu cung'),
        ),
        const CategoriesCompanion(
          categoryId: Value(2),
          categoryName: Value('Phu kien'),
          description: Value('Vong co, day dat va tui van chuyen'),
        ),
        const CategoriesCompanion(
          categoryId: Value(3),
          categoryName: Value('Do choi'),
          description: Value('Do choi giup thu cung van dong moi ngay'),
        ),
        const CategoriesCompanion(
          categoryId: Value(4),
          categoryName: Value('Suc khoe'),
          description: Value('Cham soc suc khoe va ve sinh'),
        ),
      ]);

      batch.insertAll(products, [
        ProductsCompanion(
          productId: const Value(1),
          categoryId: const Value(1),
          productName: const Value('Hat huu co khong ngu coc'),
          description: const Value(
            'Cong thuc giau dam, phu hop cho cho meo nhay cam voi ngu coc.',
          ),
          price: const Value(24.99),
          stockQuantity: const Value(42),
          weight: const Value(1.5),
          brand: const Value('Paw & Bag'),
          thumbnail: const Value(CloudinaryConstants.productKibbleUrl),
          averageRating: const Value(4.8),
          reviewCount: const Value(126),
          isFeatured: const Value(true),
          createdAt: Value(DateTime.now()),
        ),
        ProductsCompanion(
          productId: const Value(2),
          categoryId: const Value(3),
          productName: const Value('Can cau long sac mau'),
          description: const Value(
            'Do choi tuong tac giup meo giai toa nang luong va gan ket voi chu.',
          ),
          price: const Value(12.50),
          stockQuantity: const Value(68),
          brand: const Value('PetJoy'),
          thumbnail: const Value(CloudinaryConstants.productFeatherWandUrl),
          averageRating: const Value(4.7),
          reviewCount: const Value(89),
          isFeatured: const Value(true),
          createdAt: Value(DateTime.now()),
        ),
      ]);
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
