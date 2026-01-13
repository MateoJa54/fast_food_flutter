import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/cart_providers.dart';

class CartIconButton extends ConsumerWidget {
  const CartIconButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final count = cart.items.fold<int>(0, (sum, i) => sum + i.qty);

    return IconButton(
      tooltip: 'Carrito',
      onPressed: () => context.push('/cart'),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.shopping_cart),
          if (count > 0)
            Positioned(
              right: -6,
              top: -6,
              child: CircleAvatar(
                radius: 9,
                child: Text(
                  '$count',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
