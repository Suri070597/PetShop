import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../domain/order_models.dart';

/// Màn hình chức năng 29 - Select Payment Method.
///
/// Khi người dùng bấm xác nhận, màn hình trả mã phương thức thanh toán về
/// CheckoutScreen bằng Navigator.pop(context, selectedMethod).
class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({
    super.key,
    this.initialMethod = PaymentMethodCodes.cod,
  });

  final String initialMethod;

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  late String _selectedMethod;

  @override
  void initState() {
    super.initState();
    _selectedMethod = widget.initialMethod;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(title: const Text('Phương thức thanh toán')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Chọn cách bạn muốn thanh toán',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bạn có thể thay đổi phương thức trước khi đặt hàng.',
            style: TextStyle(color: AppColors.muted, fontSize: 15),
          ),
          const SizedBox(height: 22),
          _PaymentOptionCard(
            value: PaymentMethodCodes.cod,
            groupValue: _selectedMethod,
            icon: Icons.local_shipping_outlined,
            title: 'Thanh toán khi nhận hàng',
            subtitle: 'Thanh toán cho nhân viên giao hàng khi nhận sản phẩm.',
            onChanged: (value) => setState(() => _selectedMethod = value),
          ),
          const SizedBox(height: 14),
          _PaymentOptionCard(
            value: PaymentMethodCodes.bankTransfer,
            groupValue: _selectedMethod,
            icon: Icons.account_balance_outlined,
            title: 'Chuyển khoản ngân hàng',
            subtitle: 'Bản demo sẽ mô phỏng giao dịch thành công ngay lập tức.',
            onChanged: (value) => setState(() => _selectedMethod = value),
          ),
          if (_selectedMethod == PaymentMethodCodes.bankTransfer) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.mist,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.line),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thông tin chuyển khoản demo',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text('Ngân hàng: PetJoy Bank'),
                  Text('Số tài khoản: 0123 456 789'),
                  Text('Chủ tài khoản: PETJOY SHOP'),
                  SizedBox(height: 8),
                  Text(
                    'Không thực hiện giao dịch thật trong phiên bản local.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, _selectedMethod),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forest,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Xác nhận phương thức',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentOptionCard extends StatelessWidget {
  const _PaymentOptionCard({
    required this.value,
    required this.groupValue,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  final String value;
  final String groupValue;
  final IconData icon;
  final String title;
  final String subtitle;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.forest : AppColors.line,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.forest.withValues(alpha: 0.1)
                    : AppColors.mist,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color: selected ? AppColors.forest : AppColors.muted,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: groupValue,
              activeColor: AppColors.forest,
              onChanged: (newValue) {
                if (newValue != null) {
                  onChanged(newValue);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
