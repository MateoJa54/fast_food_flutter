import 'cart_item_snapshot.dart';
class CartState {
  final List<CartItemSnapshot> items;
  final String? couponCode;
  final double discountAmount;

  const CartState({
    required this.items,
    this.couponCode,
    this.discountAmount = 0,
  });

  double get subtotal => items.fold(0, (sum, i) => sum + i.lineTotal);
  double get total => (subtotal - discountAmount).clamp(0, double.infinity);

  CartState copyWith({
    List<CartItemSnapshot>? items,
    String? couponCode,
    double? discountAmount,
    bool clearCouponCode = false,
  }) {
    return CartState(
      items: items ?? this.items,
      couponCode: clearCouponCode ? null : (couponCode ?? this.couponCode),
      discountAmount: discountAmount ?? this.discountAmount,
    );
  }
}
