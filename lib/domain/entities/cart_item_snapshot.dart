class CartItemSnapshot {
  final String productId;
  final String nameSnapshot;
  final double priceSnapshot;
  final List<String> tagsSnapshot;
  final int qty;
  final String? notes;
  final List<Map<String, dynamic>> modifiersSnapshot; // simple por ahora

  const CartItemSnapshot({
    required this.productId,
    required this.nameSnapshot,
    required this.priceSnapshot,
    required this.tagsSnapshot,
    required this.qty,
    this.notes,
    this.modifiersSnapshot = const [],
  });

  double get lineTotal => (priceSnapshot * qty);
}
