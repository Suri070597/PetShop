import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/datasources/drift/app_database.dart';
import '../../../auth/providers/auth_controller.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../vouchers/presentation/controllers/vouchers_controller.dart';
import '../../data/order_repository.dart';
import '../../domain/order_models.dart';
import '../providers/order_provider.dart';

/// Màn hình chức năng 27 - Checkout.
///
/// Luồng xử lý:
/// Cart -> nhập địa chỉ -> chọn payment -> chọn voucher -> transaction tạo Order và
/// OrderDetails -> trừ tồn kho -> xóa CartItems -> mở Order Detail.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _receiverNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _provinceController = TextEditingController();
  final _districtController = TextEditingController();
  final _wardController = TextEditingController();
  final _streetController = TextEditingController();
  final _voucherCodeController = TextEditingController();

  int? _addressId;
  String _paymentMethod = PaymentMethodCodes.cod;
  Voucher? _selectedVoucher;
  bool _isLoadingAddress = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userId = _getAuthenticatedUserId();

      // Người dùng mở trực tiếp Checkout nhưng chưa đăng nhập.
      if (userId == null) {
        _redirectToLogin();
        return;
      }

      await ref.read(cartControllerProvider).loadCart();
      await _loadDefaultAddress(userId);
    });
  }

  @override
  void dispose() {
    _receiverNameController.dispose();
    _phoneController.dispose();
    _provinceController.dispose();
    _districtController.dispose();
    _wardController.dispose();
    _streetController.dispose();
    _voucherCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadDefaultAddress(String userId) async {
    try {
      final address = await ref
          .read(orderRepositoryProvider)
          .getDefaultAddress(userId);

      if (!mounted) {
        return;
      }

      if (address != null) {
        _addressId = address.addressId;
        _receiverNameController.text = address.receiverName;
        _phoneController.text = address.phone;
        _provinceController.text = address.province;
        _districtController.text = address.district;
        _wardController.text = address.ward;
        _streetController.text = address.street;
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_friendlyError(error))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingAddress = false);
      }
    }
  }

  double _calculateDiscount(double subTotal) {
    if (_selectedVoucher == null) return 0.0;
    if (subTotal < _selectedVoucher!.minOrderValue) return 0.0;
    final rawDiscount = subTotal * (_selectedVoucher!.discountPercent / 100);
    if (_selectedVoucher!.maxDiscount > 0 && rawDiscount > _selectedVoucher!.maxDiscount) {
      return _selectedVoucher!.maxDiscount;
    }
    return rawDiscount;
  }

  Future<void> _selectVoucherModal(BuildContext context, double subTotal) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final vouchersAsync = ref.watch(vouchersProvider);
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.65,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Mã giảm giá',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _voucherCodeController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              hintText: 'Nhập mã giảm giá (ví dụ: PETJOYNEW)',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: AppColors.mist,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () async {
                            final code = _voucherCodeController.text.trim();
                            if (code.isEmpty) return;
                            try {
                              final voucher = await ref
                                  .read(vouchersControllerProvider)
                                  .applyVoucher(code, subTotal);
                              setState(() => _selectedVoucher = voucher);
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Áp dụng mã ${voucher.code} thành công!'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(e.toString().replaceAll('Exception: ', '')),
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.forest,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          child: const Text('Áp dụng'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Mã giảm giá có sẵn',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: vouchersAsync.when(
                        loading: () => const Center(
                          child: CircularProgressIndicator(color: AppColors.forest),
                        ),
                        error: (error, _) => Center(
                          child: Text('Đã xảy ra lỗi: $error'),
                        ),
                        data: (vouchers) {
                          if (vouchers.isEmpty) {
                            return const Center(
                              child: Text('Hiện không có mã giảm giá nào.'),
                            );
                          }
                          return ListView.separated(
                            itemCount: vouchers.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final voucher = vouchers[index];
                              final isEligible = subTotal >= voucher.minOrderValue;
                              final isSelected = _selectedVoucher?.voucherId == voucher.voucherId;

                              return InkWell(
                                onTap: isEligible
                                    ? () {
                                        setState(() => _selectedVoucher = voucher);
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Áp dụng mã ${voucher.code} thành công!',
                                            ),
                                          ),
                                        );
                                      }
                                    : null,
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.leaf.withValues(alpha: 0.1)
                                        : (isEligible ? Colors.white : Colors.grey.shade100),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.forest
                                          : (isEligible ? Colors.grey.shade300 : Colors.grey.shade200),
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isEligible
                                              ? AppColors.forest.withValues(alpha: 0.1)
                                              : Colors.grey.shade300,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.confirmation_number_outlined,
                                          color: isEligible ? AppColors.forest : Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              voucher.code,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: isEligible ? AppColors.ink : Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              voucher.voucherName,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: isEligible ? AppColors.muted : Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              isEligible
                                                  ? 'Giảm ${voucher.discountPercent}% (Tối đa \$${voucher.maxDiscount.toStringAsFixed(2)})'
                                                  : 'Đơn tối thiểu \$${voucher.minOrderValue.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: isEligible ? AppColors.forest : AppColors.danger,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_circle,
                                          color: AppColors.forest,
                                        )
                                      else if (isEligible)
                                        const Text(
                                          'Áp dụng',
                                          style: TextStyle(
                                            color: AppColors.forest,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(title: const Text('Thanh toán')),
      body: cartAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: _friendlyError(error),
          onRetry: () => ref.read(cartControllerProvider).loadCart(),
        ),
        data: (items) {
          if (items.isEmpty) {
            return _EmptyCheckout(
              onBackToCart: () => Navigator.pushReplacementNamed(
                context,
                RouteNames.cart,
              ),
            );
          }

          final subTotal = items.fold<double>(
            0,
            (sum, item) => sum + item.totalPrice,
          );
          final shippingFee = OrderRepository.calculateShippingFee(subTotal);
          final discountAmount = _calculateDiscount(subTotal);
          final total = (subTotal + shippingFee - discountAmount).clamp(0.0, double.infinity);

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
              children: [
                _SectionCard(
                  title: 'Địa chỉ nhận hàng',
                  icon: Icons.location_on_outlined,
                  child: _isLoadingAddress
                      ? const Padding(
                          padding: EdgeInsets.all(22),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : Column(
                          children: [
                            _AddressField(
                              controller: _receiverNameController,
                              label: 'Tên người nhận',
                              icon: Icons.person_outline,
                              validator: _requiredValidator,
                            ),
                            const SizedBox(height: 12),
                            _AddressField(
                              controller: _phoneController,
                              label: 'Số điện thoại',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              validator: _phoneValidator,
                            ),
                            const SizedBox(height: 12),
                            _AddressField(
                              controller: _provinceController,
                              label: 'Tỉnh/Thành phố',
                              icon: Icons.apartment_outlined,
                              validator: _requiredValidator,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _AddressField(
                                    controller: _districtController,
                                    label: 'Quận/Huyện',
                                    validator: _requiredValidator,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _AddressField(
                                    controller: _wardController,
                                    label: 'Phường/Xã',
                                    validator: _requiredValidator,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _AddressField(
                              controller: _streetController,
                              label: 'Số nhà, tên đường',
                              icon: Icons.home_outlined,
                              validator: _requiredValidator,
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Phương thức thanh toán',
                  icon: Icons.payment_outlined,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _selectPaymentMethod,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppColors.mist,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(
                              _paymentMethod == PaymentMethodCodes.cod
                                  ? Icons.local_shipping_outlined
                                  : Icons.account_balance_outlined,
                              color: AppColors.forest,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  PaymentMethodCodes.label(_paymentMethod),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _paymentMethod == PaymentMethodCodes.cod
                                      ? 'Thanh toán sau khi nhận sản phẩm'
                                      : 'Mô phỏng thanh toán thành công',
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Mã giảm giá',
                  icon: Icons.confirmation_number_outlined,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _selectVoucherModal(context, subTotal),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppColors.mist,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Icon(
                              Icons.local_offer_outlined,
                              color: AppColors.forest,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _selectedVoucher == null
                                ? const Text(
                                    'Chọn hoặc nhập mã giảm giá',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.muted,
                                    ),
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.forest,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              _selectedVoucher!.code,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '-${MoneyFormatter.usd(discountAmount)}',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.forest,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _selectedVoucher!.voucherName,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          if (_selectedVoucher != null)
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.grey),
                              onPressed: () => setState(() => _selectedVoucher = null),
                            )
                          else
                            const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Sản phẩm (${items.length})',
                  icon: Icons.shopping_bag_outlined,
                  child: Column(
                    children: [
                      for (var index = 0; index < items.length; index++) ...[
                        _CheckoutProductRow(item: items[index]),
                        if (index != items.length - 1)
                          const Divider(height: 24),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Tóm tắt thanh toán',
                  icon: Icons.receipt_long_outlined,
                  child: Column(
                    children: [
                      _PriceRow(label: 'Tạm tính', value: subTotal),
                      const SizedBox(height: 10),
                      _PriceRow(
                        label: 'Phí vận chuyển',
                        value: shippingFee,
                        freeLabel: shippingFee == 0 ? 'Miễn phí' : null,
                      ),
                      if (discountAmount > 0) ...[
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Giảm giá Voucher',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.forest,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '-${MoneyFormatter.usd(discountAmount)}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.forest,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const Divider(height: 28),
                      _PriceRow(
                        label: 'Tổng thanh toán',
                        value: total,
                        emphasized: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : () => _placeOrder(subTotal),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forest,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: _isSubmitting
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.lock_outline),
                    label: Text(
                      _isSubmitting ? 'Đang tạo đơn...' : 'Đặt hàng',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String? _getAuthenticatedUserId() {
    final authUser = ref.read(authControllerProvider).valueOrNull;
    if (authUser != null) {
      return authUser.id;
    }
    final savedUserId = ref.read(preferencesServiceProvider).currentUserId;
    final firebaseUser = ref.read(authRepositoryProvider).firebaseUser;

    return savedUserId ?? firebaseUser?.uid;
  }

  void _redirectToLogin() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Vui lòng đăng nhập trước khi thanh toán.',
        ),
      ),
    );

    Navigator.pushNamedAndRemoveUntil(
      context,
      RouteNames.login,
      (route) => false,
    );
  }

  Future<void> _selectPaymentMethod() async {
    final result = await Navigator.pushNamed(
      context,
      RouteNames.paymentMethod,
      arguments: _paymentMethod,
    );

    if (!mounted || result is! String) {
      return;
    }

    setState(() => _paymentMethod = result);
  }

  Future<void> _placeOrder(double subTotal) async {
    final userId = _getAuthenticatedUserId();

    if (userId == null) {
      _redirectToLogin();
      return;
    }

    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final discountAmount = _calculateDiscount(subTotal);
      final orderId = await ref.read(orderRepositoryProvider).checkout(
            userId: userId,
            address: CheckoutAddressInput(
              addressId: _addressId,
              receiverName: _receiverNameController.text,
              phone: _phoneController.text,
              province: _provinceController.text,
              district: _districtController.text,
              ward: _wardController.text,
              street: _streetController.text,
            ),
            paymentMethod: _paymentMethod,
            voucherId: _selectedVoucher?.voucherId,
            discountAmount: discountAmount,
          );

      await ref.read(cartControllerProvider).loadCart();
      ref.invalidate(orderHistoryProvider);
      ref.invalidate(orderDetailProvider(orderId));

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đặt hàng #$orderId thành công.')),
      );
      Navigator.pushReplacementNamed(
        context,
        RouteNames.orderDetail,
        arguments: orderId,
      );
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyError(error))),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập thông tin này';
    }
    return null;
  }

  String? _phoneValidator(String? value) {
    final requiredError = _requiredValidator(value);
    if (requiredError != null) {
      return requiredError;
    }

    final normalized = value!.replaceAll(RegExp(r'\s+'), '');
    if (!RegExp(r'^[0-9+]{9,15}$').hasMatch(normalized)) {
      return 'Số điện thoại không hợp lệ';
    }
    return null;
  }

  String _friendlyError(Object error) {
    return error
        .toString()
        .replaceFirst('Bad state: ', '')
        .replaceFirst('Exception: ', '');
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.forest),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _AddressField extends StatelessWidget {
  const _AddressField({
    required this.controller,
    required this.label,
    this.icon,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon == null ? null : Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _CheckoutProductRow extends StatelessWidget {
  const _CheckoutProductRow({required this.item});

  final CartItemDisplay item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 62,
            height: 62,
            color: AppColors.mist,
            child: item.imageUrl.isEmpty
                ? const Icon(Icons.pets, color: AppColors.muted)
                : Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.pets, color: AppColors.muted),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.productName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${MoneyFormatter.usd(item.unitPrice)} × ${item.quantity}',
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          MoneyFormatter.usd(item.totalPrice),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.forest,
          ),
        ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.freeLabel,
    this.emphasized = false,
  });

  final String label;
  final double value;
  final String? freeLabel;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: emphasized ? 17 : 15,
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w500,
              color: emphasized ? AppColors.ink : AppColors.muted,
            ),
          ),
        ),
        Text(
          freeLabel ?? MoneyFormatter.usd(value),
          style: TextStyle(
            fontSize: emphasized ? 22 : 16,
            fontWeight: emphasized ? FontWeight.w900 : FontWeight.w700,
            color: freeLabel != null || emphasized
                ? AppColors.forest
                : AppColors.ink,
          ),
        ),
      ],
    );
  }
}

class _EmptyCheckout extends StatelessWidget {
  const _EmptyCheckout({required this.onBackToCart});

  final VoidCallback onBackToCart;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.remove_shopping_cart_outlined,
            size: 74,
            color: AppColors.muted,
          ),
          const SizedBox(height: 16),
          const Text(
            'Không có sản phẩm để thanh toán',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: onBackToCart,
            child: const Text('Quay lại giỏ hàng'),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.danger),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}
