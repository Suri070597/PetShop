import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_shop/data/datasources/drift/app_database.dart';
import 'package:pet_shop/features/orders/data/order_repository.dart';
import 'package:pet_shop/features/orders/domain/order_models.dart';

void main() {
  late AppDatabase database;
  late OrderRepository repository;

  const userId = 'checkout-user';

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    repository = OrderRepository(database);

    await database.into(database.localUsers).insert(
      LocalUsersCompanion.insert(
        id: userId,
        fullName: 'Người mua hàng',
        email: 'checkout@petjoy.test',
        emailVerified: const Value(true),
      ),
    );
    final categoryId = await database.into(database.categories).insert(
      CategoriesCompanion.insert(
        categoryName: 'Thức ăn',
        description: const Value('Danh mục kiểm thử'),
      ),
    );
    final productId = await database.into(database.products).insert(
      ProductsCompanion.insert(
        categoryId: categoryId,
        productName: 'Hạt cho mèo',
        description: 'Sản phẩm kiểm thử',
        price: 18.5,
        stockQuantity: const Value(5),
      ),
    );
    await database.into(database.cartItems).insert(
      CartItemsCompanion.insert(
        userId: userId,
        productId: productId,
        quantity: const Value(1),
        unitPrice: 18.5,
      ),
    );
  });

  tearDown(() => database.close());

  test('không thể đặt hàng khi người dùng chưa có địa chỉ đã lưu', () async {
    final checkout = repository.checkout(
      userId: userId,
      address: const CheckoutAddressInput(
        receiverName: 'Người mua hàng',
        phone: '0912345678',
        province: 'Hà Nội',
        district: 'Cầu Giấy',
        ward: 'Dịch Vọng',
        street: 'Số 10 Trần Thái Tông',
      ),
      paymentMethod: PaymentMethodCodes.cod,
    );

    await expectLater(
      checkout,
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('thêm địa chỉ nhận hàng'),
        ),
      ),
    );

    expect(await database.select(database.orders).get(), isEmpty);
    expect(await database.select(database.cartItems).get(), hasLength(1));
    expect(await database.select(database.addresses).get(), isEmpty);
  });
}
