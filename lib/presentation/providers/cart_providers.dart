import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/cart_item_snapshot.dart';
import '../../domain/entities/cart_state.dart';
import '../../domain/entities/product.dart';

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() => const CartState(items: []);

  void addProduct(Product p, {int qty = 1, String? notes}) {
    // Si ya existe, incrementa qty
    final idx = state.items.indexWhere((i) => i.productId == p.id);
    if (idx >= 0) {
      final updated = [...state.items];
      final old = updated[idx];
      updated[idx] = CartItemSnapshot(
        productId: old.productId,
        nameSnapshot: old.nameSnapshot,
        priceSnapshot: old.priceSnapshot,
        tagsSnapshot: old.tagsSnapshot,
        qty: old.qty + qty,
        notes: old.notes,
        modifiersSnapshot: old.modifiersSnapshot,
      );
      state = state.copyWith(items: updated);
      return;
    }

    final item = CartItemSnapshot(
      productId: p.id,
      nameSnapshot: p.name,
      priceSnapshot: p.basePrice,
      tagsSnapshot: p.tags,
      qty: qty,
      notes: notes,
      modifiersSnapshot: const [],
    );
    state = state.copyWith(items: [...state.items, item]);
  }

  void inc(String productId) {
    final updated = state.items.map((i) {
      if (i.productId != productId) return i;
      return CartItemSnapshot(
        productId: i.productId,
        nameSnapshot: i.nameSnapshot,
        priceSnapshot: i.priceSnapshot,
        tagsSnapshot: i.tagsSnapshot,
        qty: i.qty + 1,
        notes: i.notes,
        modifiersSnapshot: i.modifiersSnapshot,
      );
    }).toList();

    state = state.copyWith(items: updated);
  }

  void dec(String productId) {
    final updated = <CartItemSnapshot>[];

    for (final i in state.items) {
      if (i.productId != productId) {
        updated.add(i);
        continue;
      }

      final newQty = i.qty - 1;
      if (newQty > 0) {
        updated.add(CartItemSnapshot(
          productId: i.productId,
          nameSnapshot: i.nameSnapshot,
          priceSnapshot: i.priceSnapshot,
          tagsSnapshot: i.tagsSnapshot,
          qty: newQty,
          notes: i.notes,
          modifiersSnapshot: i.modifiersSnapshot,
        ));
      }
    }

    state = state.copyWith(items: updated);
  }

  void remove(String productId) {
    state = state.copyWith(
      items: state.items.where((i) => i.productId != productId).toList(),
    );
  }

  void clear() {
    state = const CartState(items: []);
  }

  void applyCouponResult({required String code, required double discountAmount}) {
    state = state.copyWith(couponCode: code, discountAmount: discountAmount);
  }

  void clearCoupon() {
    state = state.copyWith(discountAmount: 0, clearCouponCode: true);
  }
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(() {
  return CartNotifier();
});
