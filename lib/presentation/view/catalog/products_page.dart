import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/cart_icon_button.dart';
import '../../providers/cart_providers.dart';
import '../../providers/catalog_providers.dart';

class ProductsPage extends ConsumerStatefulWidget {
  const ProductsPage({
    super.key,
    required this.categoryId,
    this.categoryName,
  });

  final String categoryId;
  final String? categoryName;

  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  String _q = '';

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/categories'); // ✅ tu fallback real
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncProducts = ref.watch(productsProvider(widget.categoryId));
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text(widget.categoryName ?? 'Productos'),
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Volver',
              onPressed: () => _handleBack(context),
            ),
            actions: const [
              CartIconButton(),
            ],
          ),

          // Search
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            sliver: SliverToBoxAdapter(
              child: TextField(
                onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Buscar productos…',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: asyncProducts.when(
              data: (products) {
                if (products.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _EmptyState(
                      title: 'No hay productos',
                      subtitle: 'Esta categoría no tiene productos disponibles por ahora.',
                      icon: Icons.fastfood_outlined,
                      buttonText: 'Volver a categorías',
                      onPressed: () => context.go('/categories'),
                    ),
                  );
                }

                final filtered = products.where((p) {
                  if (_q.isEmpty) return true;
                  final name = p.name.toLowerCase();
                  final desc = p.description.toLowerCase();
                  final tags = (p.tags ?? const <String>[]).join(' ').toLowerCase();
                  return name.contains(_q) || desc.contains(_q) || tags.contains(_q);
                }).toList();

                if (filtered.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _EmptyState(
                      title: 'Sin resultados',
                      subtitle: 'No encontramos productos con “$_q”.',
                      icon: Icons.search_off,
                      buttonText: 'Limpiar búsqueda',
                      onPressed: () => setState(() => _q = ''),
                    ),
                  );
                }

                return SliverList.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final p = filtered[i];
                    final tags = (p.tags ?? const <String>[]).where((t) => t.trim().isNotEmpty).toList();

                    return _ProductCard(
                      name: p.name,
                      description: p.description,
                      price: p.basePrice,
                      imageUrl: p.imageUrl,
                      tags: tags,
                      isAvailable: p.isAvailable ?? true,
                      onTap: () => context.push('/product/${p.id}'),
                      onQuickAdd: (p.isAvailable ?? true)
                          ? () {
                              ref.read(cartProvider.notifier).addProduct(p);
                              ScaffoldMessenger.of(context)
                                ..clearSnackBars()
                                ..showSnackBar(
                                  SnackBar(
                                    behavior: SnackBarBehavior.floating,
                                    margin: const EdgeInsets.all(12),
                                    content: const Text('Agregado al carrito'),
                                    action: SnackBarAction(
                                      label: 'Ver',
                                      onPressed: () => context.push('/cart'),
                                    ),
                                  ),
                                );
                            }
                          : null,
                    );
                  },
                );
              },
              loading: () => const SliverToBoxAdapter(child: _ProductsSkeleton()),
              error: (e, _) => SliverToBoxAdapter(
                child: _ErrorState(
                  message: 'Error cargando productos:\n$e',
                  onRetry: () => ref.invalidate(productsProvider(widget.categoryId)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- UI components ----------------

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.tags,
    required this.isAvailable,
    required this.onTap,
    required this.onQuickAdd,
  });

  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final List<String> tags;
  final bool isAvailable;
  final VoidCallback onTap;
  final VoidCallback? onQuickAdd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.15)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                imageUrl,
                width: 92,
                height: 92,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 92,
                  height: 92,
                  color: scheme.surfaceContainerHighest,
                  alignment: Alignment.center,
                  child: Icon(Icons.fastfood, color: scheme.onSurfaceVariant),
                ),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título + estado
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      if (!isAvailable)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: scheme.errorContainer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Agotado',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: scheme.onErrorContainer,
                                ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  Text(
                    description.trim().isEmpty ? 'Sin descripción.' : description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),

                  const SizedBox(height: 10),

                  // Tags
                  if (tags.isNotEmpty)
                    SizedBox(
                      height: 28,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: tags.length.clamp(0, 3),
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (_, i) => _TagChip(text: tags[i]),
                      ),
                    ),

                  if (tags.isNotEmpty) const SizedBox(height: 10),

                  // Precio + quick add
                  Row(
                    children: [
                      Text(
                        '\$${price.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: scheme.primary,
                            ),
                      ),
                      const Spacer(),
                      FilledButton.tonal(
                        onPressed: onQuickAdd,
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: const Text('Agregar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800)),
    );
  }
}

class _ProductsSkeleton extends StatelessWidget {
  const _ProductsSkeleton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget box({required double h, double? w}) => Container(
          height: h,
          width: w,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
        );

    return Column(
      children: List.generate(
        5,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                box(h: 92, w: 92),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      box(h: 14, w: 180),
                      const SizedBox(height: 10),
                      box(h: 12, w: 220),
                      const SizedBox(height: 6),
                      box(h: 12, w: 160),
                      const SizedBox(height: 12),
                      box(h: 14, w: 90),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.buttonText,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String buttonText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Icon(icon, size: 56, color: scheme.onSurfaceVariant),
          const SizedBox(height: 10),
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(subtitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 14),
          FilledButton(onPressed: onPressed, child: Text(buttonText)),
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
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: scheme.onErrorContainer),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onErrorContainer),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
