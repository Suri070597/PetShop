/// Domain model for a cart item.
class CartItem {
  final int cartItemId;
  final String userId;
  final int productId;
  final int quantity;
  final double unitPrice;

  CartItem({
    required this.cartItemId,
    required this.userId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
  });
}