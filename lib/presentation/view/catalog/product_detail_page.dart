import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/cart_providers.dart';
import '../../providers/catalog_providers.dart';

class ProductDetailPage extends ConsumerWidget {
  const ProductDetailPage({super.key, required this.productId});
  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProduct = ref.watch(productDetailProvider(productId));
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle'),
       leading: IconButton(
  icon: const Icon(Icons.arrow_back),
  onPressed: () {
    if (context.canPop()) {
      context.pop();
    } else {
      // Si no hay historial (porque llegaste con go), vuelve a categorías
      context.go('/categories');
    }
  },
),
        actions: [
          // Botón carrito con contador
          IconButton(
            tooltip: 'Carrito',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_cart),
                if (cart.items.isNotEmpty)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: CircleAvatar(
                      radius: 9,
                      child: Text(
                        '${cart.items.length}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => context.push('/cart'),
          )
        ],
      ),
      body: asyncProduct.when(
        data: (p) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                p.imageUrl,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 220,
                  alignment: Alignment.center,
                  child: const Icon(Icons.fastfood, size: 60),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              p.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(p.description),
            const SizedBox(height: 12),
            Text(
              '\$${p.basePrice.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Agregar y opcionalmente navegar
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  ref.read(cartProvider.notifier).addProduct(p);

                  // Mensaje corto
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Agregado al carrito'),
                      action: SnackBarAction(
                        label: 'Ver',
                        onPressed: () => context.push('/cart'),
                      ),
                    ),
                  );
                },
                child: const Text('Agregar al carrito'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.push('/cart'),
                child: const Text('Ver carrito'),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error cargando detalle:\n$e'),
          ),
        ),
      ),
    );
  }
}
