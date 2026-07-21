import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/cart_provider.dart';

/// Widget to display a single cart item with quantity controls (support inline text edit).
class CartItemWidget extends StatefulWidget {
  const CartItemWidget({
    super.key,
    required this.item,
    this.onQuantityChanged,
    this.onRemove,
  });

  final CartItemDisplay item;
  final void Function(int newQuantity)? onQuantityChanged;
  final VoidCallback? onRemove;

  @override
  State<CartItemWidget> createState() => _CartItemWidgetState();
}

class _CartItemWidgetState extends State<CartItemWidget> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.item.quantity}');
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant CartItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.quantity != widget.item.quantity && !_focusNode.hasFocus) {
      _controller.text = '${widget.item.quantity}';
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _submitQuantity();
    }
  }

  void _submitQuantity() {
    final text = _controller.text.trim();
    final parsed = int.tryParse(text);
    final maxQty = widget.item.maxOrderQty;

    if (parsed == null || parsed < 1) {
      // Revert to 1 if negative, zero, or invalid number
      _controller.text = '1';
      if (widget.item.quantity != 1) {
        widget.onQuantityChanged?.call(1);
      }
    } else if (parsed > maxQty) {
      // Cap at max stock (up to 5000)
      _controller.text = '$maxQty';
      if (widget.item.quantity != maxQty) {
        widget.onQuantityChanged?.call(maxQty);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Số lượng tối đa có thể chọn là $maxQty'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      if (widget.item.quantity != parsed) {
        widget.onQuantityChanged?.call(parsed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxQty = widget.item.maxOrderQty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 90,
              height: 90,
              color: AppColors.mist,
              child: widget.item.imageUrl.isEmpty
                  ? const Icon(
                      Icons.pets,
                      size: 40,
                      color: AppColors.muted,
                    )
                  : Image.network(
                      widget.item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.pets,
                        size: 40,
                        color: AppColors.muted,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),

          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product name
                Text(
                  widget.item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),

                // Unit price & Stock notice
                Row(
                  children: [
                    Text(
                      MoneyFormatter.usd(widget.item.unitPrice),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.forest,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(Kho: $maxQty)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Quantity controls (Button - TextField - Button)
                Row(
                  children: [
                    _QuantityControl(
                      icon: Icons.remove,
                      enabled: widget.item.quantity > 1,
                      onTap: () {
                        if (widget.item.quantity > 1) {
                          final newQty = widget.item.quantity - 1;
                          _controller.text = '$newQty';
                          widget.onQuantityChanged?.call(newQty);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 52,
                      height: 36,
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(vertical: 6),
                          isDense: true,
                          fillColor: AppColors.mist,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.forest,
                              width: 1.5,
                            ),
                          ),
                        ),
                        onSubmitted: (_) => _submitQuantity(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _QuantityControl(
                      icon: Icons.add,
                      enabled: widget.item.quantity < maxQty,
                      onTap: () {
                        if (widget.item.quantity < maxQty) {
                          final newQty = widget.item.quantity + 1;
                          _controller.text = '$newQty';
                          widget.onQuantityChanged?.call(newQty);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Số lượng tối đa có thể chọn là $maxQty'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                    const Spacer(),

                    // Total price
                    Text(
                      MoneyFormatter.usd(widget.item.totalPrice),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.forest,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Delete button
          Column(
            children: [
              GestureDetector(
                onTap: widget.onRemove,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: AppColors.danger,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Small round button for quantity adjustment.
class _QuantityControl extends StatelessWidget {
  const _QuantityControl({
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled ? AppColors.mist : AppColors.mist.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: enabled ? AppColors.ink : AppColors.muted,
          size: 18,
        ),
      ),
    );
  }
}