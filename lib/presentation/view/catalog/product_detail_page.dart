import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/cart_providers.dart';
import '../../providers/catalog_providers.dart';

class ProductDetailPage extends ConsumerWidget {
  const ProductDetailPage({super.key, required this.productId});
  final String productId;

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/categories');
    }
  }

  void _toast(BuildContext context, String msg, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          content: Text(msg),
          action: action,
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProduct = ref.watch(productDetailProvider(productId));
    final cart = ref.watch(cartProvider);
    final scheme = Theme.of(context).colorScheme;

    final count = cart.items.fold<int>(0, (sum, i) => sum + i.qty);

    return Scaffold(
      body: asyncProduct.when(
        data: (p) {
          final tags = (p.tags ?? const <String>[]).where((t) => t.trim().isNotEmpty).toList();

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 320,
                    backgroundColor: scheme.surface,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => _handleBack(context),
                      tooltip: 'Volver',
                    ),
                    actions: [
                      IconButton(
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
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: scheme.primary,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '$count',
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          color: scheme.onPrimary,
                                          fontWeight: FontWeight.w900,
                                        ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      titlePadding: const EdgeInsetsDirectional.only(start: 16, bottom: 14, end: 16),
                      background: _HeroImage(url: p.imageUrl, title: p.name,),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120), // espacio por CTA inferior
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        [
                          // Precio + disponibilidad
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '\$${p.basePrice.toStringAsFixed(2)}',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: scheme.primary,
                                      ),
                                ),
                              ),
                              _Pill(
                                label: (p.isAvailable ?? true) ? 'Disponible' : 'No disponible',
                                bg: (p.isAvailable ?? true) ? scheme.secondaryContainer : scheme.errorContainer,
                                fg: (p.isAvailable ?? true) ? scheme.onSecondaryContainer : scheme.onErrorContainer,
                                icon: (p.isAvailable ?? true) ? Icons.check_circle_outline : Icons.block,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          if (tags.isNotEmpty) ...[
                            SizedBox(
                              height: 34,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: tags.length.clamp(0, 6),
                                separatorBuilder: (_, __) => const SizedBox(width: 8),
                                itemBuilder: (_, i) => _TagChip(text: tags[i]),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Descripción en card elegante
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: scheme.surface,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.15)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.info_outline, color: scheme.primary),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Descripción',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  (p.description.trim().isEmpty) ? 'Sin descripción disponible.' : p.description,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Sugerencias rápidas (look&feel KFC)
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.local_fire_department, color: scheme.primary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Tip: combina este producto con bebida o papas para un combo.',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // ✅ CTA fijo abajo (iPhone-like)
              SafeArea(
                top: false,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.15))),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: (p.isAvailable ?? true)
                                ? () {
                                    ref.read(cartProvider.notifier).addProduct(p);
                                    _toast(
                                      context,
                                      'Agregado al carrito',
                                      action: SnackBarAction(
                                        label: 'Ver',
                                        onPressed: () => context.push('/cart'),
                                      ),
                                    );
                                  }
                                : null,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('Agregar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: () => context.push('/cart'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Icon(Icons.shopping_cart_outlined),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error cargando detalle:\n$e'),
          ),
        ),
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.url, required this.title});
  final String url;
  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: scheme.surfaceContainerHighest,
            alignment: Alignment.center,
            child: Icon(Icons.fastfood, size: 64, color: scheme.onSurfaceVariant),
          ),
        ),

        // ✅ Scrim más fuerte abajo para contraste
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.55, 0.78, 1.0],
                colors: [
                  Colors.black.withOpacity(0.00),
                  Colors.black.withOpacity(0.35),
                  Colors.black.withOpacity(0.80),
                ],
              ),
            ),
          ),
        ),

        // ✅ Título blanco con sombra, siempre legible
        Positioned(
          left: 16,
          right: 16,
          bottom: 18,
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.05,
                  shadows: const [
                    Shadow(blurRadius: 12, offset: Offset(0, 3), color: Colors.black54),
                  ],
                ),
          ),
        ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.bg, required this.fg, required this.icon});
  final String label;
  final Color bg;
  final Color fg;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
