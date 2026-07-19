import 'package:drift/drift.dart';

import '../datasources/drift/app_database.dart';

class AddressRepository {
  AddressRepository(this._database);

  final AppDatabase _database;

  Stream<List<AddressesData>> watchAddresses(String userId) {
    final query = _database.select(_database.addresses)
      ..where((table) => table.userId.equals(userId))
      ..orderBy([
        (table) => OrderingTerm(
              expression: table.isDefault,
              mode: OrderingMode.desc,
            ),
        (table) => OrderingTerm(
              expression: table.addressId,
              mode: OrderingMode.desc,
            ),
      ]);

    return query.watch();
  }

  Future<int> addAddress({
    required String userId,
    required String receiverName,
    required String phone,
    required String province,
    required String district,
    required String ward,
    required String street,
    required bool isDefault,
  }) {
    return _database.transaction(() async {
      final shouldBeDefault =
          isDefault || await _database.countAddresses(userId) == 0;

      if (shouldBeDefault) {
        await _clearDefault(userId);
      }

      return _database.into(_database.addresses).insert(
            AddressesCompanion.insert(
              userId: userId,
              receiverName: receiverName.trim(),
              phone: phone.trim(),
              province: province.trim(),
              district: district.trim(),
              ward: ward.trim(),
              street: street.trim(),
              isDefault: Value(shouldBeDefault),
            ),
          );
    });
  }

  Future<void> updateAddress({
    required int addressId,
    required String userId,
    required String receiverName,
    required String phone,
    required String province,
    required String district,
    required String ward,
    required String street,
    required bool isDefault,
  }) {
    return _database.transaction(() async {
      if (isDefault) {
        await _clearDefault(userId);
      }

      await (_database.update(_database.addresses)
            ..where((table) => table.addressId.equals(addressId))
            ..where((table) => table.userId.equals(userId)))
          .write(
        AddressesCompanion(
          receiverName: Value(receiverName.trim()),
          phone: Value(phone.trim()),
          province: Value(province.trim()),
          district: Value(district.trim()),
          ward: Value(ward.trim()),
          street: Value(street.trim()),
          isDefault: Value(isDefault),
        ),
      );
    });
  }

  Future<void> deleteAddress(AddressesData address) {
    return _database.transaction(() async {
      await (_database.delete(_database.addresses)
            ..where((table) => table.addressId.equals(address.addressId))
            ..where((table) => table.userId.equals(address.userId)))
          .go();

      if (!address.isDefault) {
        return;
      }

      final nextAddress = await (_database.select(_database.addresses)
            ..where((table) => table.userId.equals(address.userId))
            ..orderBy([
              (table) => OrderingTerm(
                    expression: table.addressId,
                    mode: OrderingMode.desc,
                  ),
            ])
            ..limit(1))
          .getSingleOrNull();

      if (nextAddress != null) {
        await setDefault(nextAddress.addressId, nextAddress.userId);
      }
    });
  }

  Future<void> setDefault(int addressId, String userId) {
    return _database.transaction(() async {
      await _clearDefault(userId);

      await (_database.update(_database.addresses)
            ..where((table) => table.addressId.equals(addressId))
            ..where((table) => table.userId.equals(userId)))
          .write(const AddressesCompanion(isDefault: Value(true)));
    });
  }

  Future<void> _clearDefault(String userId) {
    return (_database.update(_database.addresses)
          ..where((table) => table.userId.equals(userId)))
        .write(const AddressesCompanion(isDefault: Value(false)));
  }
}