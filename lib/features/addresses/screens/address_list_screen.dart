import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../core/di/dependency_injection.dart';
import '../../../data/datasources/drift/app_database.dart';
import 'address_form_screen.dart';

final currentAddressUserProvider = FutureProvider.autoDispose<LocalUser?>((
  ref,
) {
  return ref.watch(authRepositoryProvider).currentLocalUser();
});

final addressListProvider =
    StreamProvider.autoDispose<List<AddressesData>>((ref) async* {
  final user = await ref.watch(currentAddressUserProvider.future);
  if (user == null) {
    yield const [];
    return;
  }

  yield* ref.watch(addressRepositoryProvider).watchAddresses(user.id);
});

class AddressListScreen extends ConsumerWidget {
  const AddressListScreen({super.key});

  Future<void> _deleteAddress(
    BuildContext context,
    WidgetRef ref,
    AddressesData address,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa địa chỉ?'),
        content: const Text('Địa chỉ này sẽ bị xóa khỏi danh sách của bạn.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ref.read(addressRepositoryProvider).deleteAddress(address);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể xóa địa chỉ: $error')),
      );
    }
  }

  Future<void> _setDefault(
    BuildContext context,
    WidgetRef ref,
    AddressesData address,
  ) async {
    try {
      await ref
          .read(addressRepositoryProvider)
          .setDefault(address.addressId, address.userId);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể đặt mặc định: $error')),
      );
    }
  }

  void _openForm(
    BuildContext context,
    LocalUser user, {
    AddressesData? address,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddressFormScreen(
          userId: user.id,
          address: address,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(currentAddressUserProvider);
    final addressState = ref.watch(addressListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Địa chỉ đã lưu'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
      ),
      body: userState.when(
        data: (user) {
          if (user == null) {
            return const _EmptyAddressView(
              icon: Icons.lock_outline,
              title: 'Bạn chưa đăng nhập',
              message: 'Đăng nhập để quản lý địa chỉ giao hàng.',
            );
          }

          return addressState.when(
            data: (addresses) {
              if (addresses.isEmpty) {
                return _EmptyAddressView(
                  icon: Icons.location_on_outlined,
                  title: 'Chưa có địa chỉ',
                  message: 'Thêm địa chỉ giao hàng đầu tiên của bạn.',
                  buttonLabel: 'Thêm địa chỉ',
                  onPressed: () => _openForm(context, user),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
                itemCount: addresses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final address = addresses[index];
                  return _AddressCard(
                    address: address,
                    onEdit: () => _openForm(
                      context,
                      user,
                      address: address,
                    ),
                    onDelete: () => _deleteAddress(context, ref, address),
                    onSetDefault: address.isDefault
                        ? null
                        : () => _setDefault(context, ref, address),
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.forest),
            ),
            error: (error, _) => _EmptyAddressView(
              icon: Icons.error_outline,
              title: 'Không thể tải địa chỉ',
              message: error.toString(),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.forest),
        ),
        error: (error, _) => _EmptyAddressView(
          icon: Icons.error_outline,
          title: 'Không thể tải tài khoản',
          message: error.toString(),
        ),
      ),
      floatingActionButton: userState.maybeWhen(
        data: (user) => user == null
            ? null
            : FloatingActionButton.extended(
                onPressed: () => _openForm(context, user),
                backgroundColor: AppColors.forest,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: const Text('Thêm'),
              ),
        orElse: () => null,
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  final AddressesData address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onSetDefault;

  @override
  Widget build(BuildContext context) {
    final fullAddress =
        '${address.street}, ${address.ward}, ${address.district}, ${address.province}';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: address.isDefault ? AppColors.forest : AppColors.line,
            width: address.isDefault ? 1.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    address.receiverName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (address.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.forest.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Mặc định',
                      style: TextStyle(
                        color: AppColors.forest,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              address.phone,
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              fullAddress,
              style: const TextStyle(
                color: AppColors.ink,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Sửa'),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Xóa'),
                ),
                const Spacer(),
                if (onSetDefault != null)
                  TextButton(
                    onPressed: onSetDefault,
                    child: const Text('Đặt mặc định'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyAddressView extends StatelessWidget {
  const _EmptyAddressView({
    required this.icon,
    required this.title,
    required this.message,
    this.buttonLabel,
    this.onPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? buttonLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54, color: AppColors.forest),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 16,
                height: 1.35,
              ),
            ),
            if (buttonLabel != null && onPressed != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.add),
                label: Text(buttonLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}