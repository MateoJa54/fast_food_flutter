import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/cart_icon_button.dart';
import '../../providers/catalog_providers.dart';

class ProductsPage extends ConsumerWidget {
  const ProductsPage({
    super.key,
    required this.categoryId,
    this.categoryName,
  });

  final String categoryId;
  final String? categoryName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProducts = ref.watch(productsProvider(categoryId));

    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName ?? 'Productos'),
        actions: const [
  CartIconButton(),
],
      ),
      body: asyncProducts.when(
        data: (products) {
          if (products.isEmpty) {
            return const Center(child: Text('No hay productos en esta categoría.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final p = products[i];

              return InkWell(
                onTap: () => context.push('/product/${p.id}'),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            p.imageUrl,
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 90,
                              height: 90,
                              alignment: Alignment.center,
                              child: const Icon(Icons.fastfood),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                p.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '\$${p.basePrice.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error cargando productos:\n$e'),
          ),
        ),
      ),
    );
  }
}
