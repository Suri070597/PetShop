import 'package:drift/drift.dart';

import '../../core/utils/validators.dart';
import '../datasources/drift/app_database.dart';

class AddressValidationException implements Exception {
  const AddressValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AddressRepository {
  AddressRepository(this._database);

  final AppDatabase _database;

  Stream<List<AddressesData>> watchAddresses(String userId) {
    final query = _database.select(_database.addresses)
      ..where((table) => table.userId.equals(userId))
      ..orderBy([
        (table) =>
            OrderingTerm(expression: table.isDefault, mode: OrderingMode.desc),
        (table) =>
            OrderingTerm(expression: table.addressId, mode: OrderingMode.desc),
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
    _validateAddress(
      userId: userId,
      receiverName: receiverName,
      phone: phone,
      province: province,
      district: district,
      ward: ward,
      street: street,
    );

    return _database.transaction(() async {
      await _requireUser(userId);
      final addressCount = await _database.countAddresses(userId);
      final hasDefault = await _hasDefaultAddress(userId);
      final shouldBeDefault = isDefault || addressCount == 0 || !hasDefault;

      if (shouldBeDefault) {
        await _clearDefault(userId);
      }

      return _database
          .into(_database.addresses)
          .insert(
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
    _validateAddress(
      userId: userId,
      receiverName: receiverName,
      phone: phone,
      province: province,
      district: district,
      ward: ward,
      street: street,
    );

    return _database.transaction(() async {
      final current = await _requireOwnedAddress(addressId, userId);
      final hasDefault = await _hasDefaultAddress(userId);
      final shouldBeDefault = isDefault || current.isDefault || !hasDefault;

      if (shouldBeDefault && !current.isDefault) {
        await _clearDefault(userId);
      }

      final affectedRows =
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
                  isDefault: Value(shouldBeDefault),
                ),
              );

      if (affectedRows != 1) {
        throw StateError('Không thể cập nhật địa chỉ đã chọn.');
      }
    });
  }

  Future<void> deleteAddress({required int addressId, required String userId}) {
    return _database.transaction(() async {
      final address = await _requireOwnedAddress(addressId, userId);
      final affectedRows =
          await (_database.delete(_database.addresses)
                ..where((table) => table.addressId.equals(addressId))
                ..where((table) => table.userId.equals(userId)))
              .go();

      if (affectedRows != 1) {
        throw StateError('Không thể xóa địa chỉ đã chọn.');
      }

      final hasDefault = await _hasDefaultAddress(userId);
      if (!address.isDefault && hasDefault) {
        return;
      }

      final nextAddress =
          await (_database.select(_database.addresses)
                ..where((table) => table.userId.equals(userId))
                ..orderBy([
                  (table) => OrderingTerm(
                    expression: table.addressId,
                    mode: OrderingMode.desc,
                  ),
                ])
                ..limit(1))
              .getSingleOrNull();

      if (nextAddress != null) {
        await _setDefaultUnchecked(nextAddress.addressId, userId);
      }
    });
  }

  Future<void> setDefault(int addressId, String userId) {
    return _database.transaction(() async {
      final address = await _requireOwnedAddress(addressId, userId);
      if (address.isDefault) {
        return;
      }

      await _clearDefault(userId);
      await _setDefaultUnchecked(addressId, userId);
    });
  }

  Future<void> _requireUser(String userId) async {
    final user = await _database.findUserById(userId);
    if (user == null) {
      throw StateError('Không tìm thấy người dùng sở hữu địa chỉ.');
    }
  }

  Future<AddressesData> _requireOwnedAddress(
    int addressId,
    String userId,
  ) async {
    final address =
        await (_database.select(_database.addresses)
              ..where((table) => table.addressId.equals(addressId))
              ..where((table) => table.userId.equals(userId)))
            .getSingleOrNull();

    if (address == null) {
      throw StateError('Địa chỉ không tồn tại hoặc không thuộc người dùng.');
    }
    return address;
  }

  Future<bool> _hasDefaultAddress(String userId) async {
    final address =
        await (_database.select(_database.addresses)
              ..where((table) => table.userId.equals(userId))
              ..where((table) => table.isDefault.equals(true))
              ..limit(1))
            .getSingleOrNull();
    return address != null;
  }

  Future<void> _setDefaultUnchecked(int addressId, String userId) async {
    final affectedRows =
        await (_database.update(_database.addresses)
              ..where((table) => table.addressId.equals(addressId))
              ..where((table) => table.userId.equals(userId)))
            .write(const AddressesCompanion(isDefault: Value(true)));

    if (affectedRows != 1) {
      throw StateError('Không thể đặt địa chỉ mặc định.');
    }
  }

  Future<void> _clearDefault(String userId) {
    return (_database.update(_database.addresses)
          ..where((table) => table.userId.equals(userId)))
        .write(const AddressesCompanion(isDefault: Value(false)));
  }

  void _validateAddress({
    required String userId,
    required String receiverName,
    required String phone,
    required String province,
    required String district,
    required String ward,
    required String street,
  }) {
    final requiredValues = <(String, String)>[
      (userId, 'người dùng'),
      (receiverName, 'người nhận'),
      (province, 'tỉnh/thành phố'),
      (district, 'quận/huyện'),
      (ward, 'phường/xã'),
      (street, 'địa chỉ cụ thể'),
    ];

    for (final (value, label) in requiredValues) {
      final error = Validators.required(value, label);
      if (error != null) {
        throw AddressValidationException(error);
      }
    }

    final phoneError = Validators.phone(phone);
    if (phoneError != null) {
      throw AddressValidationException(phoneError);
    }
    if (receiverName.trim().length < 2) {
      throw const AddressValidationException(
        'Họ tên người nhận phải có ít nhất 2 ký tự',
      );
    }
    if (province.trim().length < 2 ||
        district.trim().length < 2 ||
        ward.trim().length < 2) {
      throw const AddressValidationException(
        'Tỉnh, quận/huyện và phường/xã phải có ít nhất 2 ký tự',
      );
    }
    if (street.trim().length < 5) {
      throw const AddressValidationException(
        'Địa chỉ cụ thể phải có ít nhất 5 ký tự',
      );
    }
  }
}
