import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_shop/data/datasources/drift/app_database.dart';
import 'package:pet_shop/data/repositories/address_repository.dart';

void main() {
  late AppDatabase database;
  late AddressRepository repository;

  const userA = 'user-a';
  const userB = 'user-b';

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    repository = AddressRepository(database);

    await database.batch((batch) {
      batch.insertAll(database.localUsers, [
        LocalUsersCompanion.insert(
          id: userA,
          fullName: 'Người dùng A',
          email: 'user-a@petjoy.test',
          emailVerified: const Value(true),
        ),
        LocalUsersCompanion.insert(
          id: userB,
          fullName: 'Người dùng B',
          email: 'user-b@petjoy.test',
          emailVerified: const Value(true),
        ),
      ]);
    });
  });

  tearDown(() => database.close());

  Future<int> addValidAddress(
    String userId, {
    String receiverName = 'Nguyễn Văn An',
    String phone = '0912345678',
    String province = 'Hà Nội',
    String district = 'Cầu Giấy',
    String ward = 'Dịch Vọng',
    String street = 'Số 10 Trần Thái Tông',
    bool isDefault = false,
  }) {
    return repository.addAddress(
      userId: userId,
      receiverName: receiverName,
      phone: phone,
      province: province,
      district: district,
      ward: ward,
      street: street,
      isDefault: isDefault,
    );
  }

  Future<List<AddressesData>> addressesOf(String userId) {
    return (database.select(database.addresses)
          ..where((table) => table.userId.equals(userId))
          ..orderBy([(table) => OrderingTerm.asc(table.addressId)]))
        .get();
  }

  group('AddressRepository business rules', () {
    test('người dùng chỉ xem được địa chỉ của mình', () async {
      await addValidAddress(userA);
      await addValidAddress(
        userB,
        receiverName: 'Trần Thị Bình',
        phone: '0987654321',
      );

      final visibleToA = await repository.watchAddresses(userA).first;

      expect(visibleToA, hasLength(1));
      expect(visibleToA.single.userId, userA);
      expect(visibleToA.single.receiverName, 'Nguyễn Văn An');
    });

    test('từ chối số điện thoại sai khi thêm hoặc sửa', () async {
      for (final invalidPhone in [
        '',
        '091234567',
        '09123456789',
        '1111111111',
        '09abcdefgh',
      ]) {
        expect(
          () => addValidAddress(userA, phone: invalidPhone),
          throwsA(isA<AddressValidationException>()),
          reason: 'Số $invalidPhone phải bị từ chối',
        );
      }

      final addressId = await addValidAddress(userA);
      expect(
        () => repository.updateAddress(
          addressId: addressId,
          userId: userA,
          receiverName: 'Nguyễn Văn An',
          phone: '1234567890',
          province: 'Hà Nội',
          district: 'Cầu Giấy',
          ward: 'Dịch Vọng',
          street: 'Số 10 Trần Thái Tông',
          isDefault: true,
        ),
        throwsA(isA<AddressValidationException>()),
      );
    });

    test('địa chỉ đầu tiên tự động trở thành mặc định', () async {
      await addValidAddress(userA, isDefault: false);

      final addresses = await addressesOf(userA);
      expect(addresses.single.isDefault, isTrue);
    });

    test('mỗi người dùng chỉ có đúng một địa chỉ mặc định', () async {
      final firstId = await addValidAddress(userA);
      final secondId = await addValidAddress(
        userA,
        receiverName: 'Nguyễn Thị Hoa',
        phone: '0812345678',
        street: 'Số 20 Xuân Thủy',
        isDefault: true,
      );

      var addresses = await addressesOf(userA);
      expect(addresses.where((item) => item.isDefault), hasLength(1));
      expect(
        addresses.singleWhere((item) => item.isDefault).addressId,
        secondId,
      );

      await repository.updateAddress(
        addressId: firstId,
        userId: userA,
        receiverName: 'Nguyễn Văn An',
        phone: '0912345678',
        province: 'Hà Nội',
        district: 'Cầu Giấy',
        ward: 'Dịch Vọng',
        street: 'Số 10 Trần Thái Tông',
        isDefault: true,
      );

      addresses = await addressesOf(userA);
      expect(addresses.where((item) => item.isDefault), hasLength(1));
      expect(
        addresses.singleWhere((item) => item.isDefault).addressId,
        firstId,
      );
    });

    test('không thể sửa, xóa hoặc đặt mặc định địa chỉ người khác', () async {
      final addressA = await addValidAddress(userA);
      final addressB = await addValidAddress(
        userB,
        receiverName: 'Trần Thị Bình',
        phone: '0987654321',
      );

      await expectLater(
        repository.updateAddress(
          addressId: addressB,
          userId: userA,
          receiverName: 'Tên bị sửa',
          phone: '0912345678',
          province: 'Hà Nội',
          district: 'Cầu Giấy',
          ward: 'Dịch Vọng',
          street: 'Số 99 Không hợp lệ',
          isDefault: true,
        ),
        throwsStateError,
      );
      await expectLater(
        repository.deleteAddress(addressId: addressB, userId: userA),
        throwsStateError,
      );
      await expectLater(
        repository.setDefault(addressB, userA),
        throwsStateError,
      );

      final addressesA = await addressesOf(userA);
      final addressesB = await addressesOf(userB);
      expect(addressesA.single.addressId, addressA);
      expect(addressesA.single.isDefault, isTrue);
      expect(addressesB.single.receiverName, 'Trần Thị Bình');
      expect(addressesB.single.isDefault, isTrue);
    });

    test('xóa địa chỉ mặc định sẽ chuyển mặc định sang địa chỉ khác', () async {
      final defaultId = await addValidAddress(userA);
      final nextId = await addValidAddress(
        userA,
        receiverName: 'Nguyễn Thị Hoa',
        phone: '0812345678',
        street: 'Số 20 Xuân Thủy',
      );

      await repository.deleteAddress(addressId: defaultId, userId: userA);

      final addresses = await addressesOf(userA);
      expect(addresses, hasLength(1));
      expect(addresses.single.addressId, nextId);
      expect(addresses.single.isDefault, isTrue);
    });

    test('ID không tồn tại không làm mất địa chỉ mặc định cũ', () async {
      final defaultId = await addValidAddress(userA);

      await expectLater(repository.setDefault(999999, userA), throwsStateError);
      await expectLater(
        repository.updateAddress(
          addressId: 999999,
          userId: userA,
          receiverName: 'Nguyễn Văn An',
          phone: '0912345678',
          province: 'Hà Nội',
          district: 'Cầu Giấy',
          ward: 'Dịch Vọng',
          street: 'Số 10 Trần Thái Tông',
          isDefault: true,
        ),
        throwsStateError,
      );
      await expectLater(
        repository.deleteAddress(addressId: 999999, userId: userA),
        throwsStateError,
      );

      final addresses = await addressesOf(userA);
      expect(addresses.single.addressId, defaultId);
      expect(addresses.single.isDefault, isTrue);
    });

    test('không thể lưu trường bắt buộc rỗng qua repository', () {
      final invalidCalls = <Future<int> Function()>[
        () => addValidAddress(userA, receiverName: ' '),
        () => addValidAddress(userA, phone: ' '),
        () => addValidAddress(userA, province: ' '),
        () => addValidAddress(userA, district: ' '),
        () => addValidAddress(userA, ward: ' '),
        () => addValidAddress(userA, street: ' '),
      ];

      for (final call in invalidCalls) {
        expect(call, throwsA(isA<AddressValidationException>()));
      }
    });
  });
}
