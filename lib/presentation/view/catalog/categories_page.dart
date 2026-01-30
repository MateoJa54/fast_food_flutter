import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/cart_icon_button.dart';
import '../../providers/catalog_providers.dart';

class CategoriesPage extends ConsumerStatefulWidget {
  const CategoriesPage({super.key});

  @override
  ConsumerState<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends ConsumerState<CategoriesPage> {
  String _q = '';

  Future<void> _signOut() async => FirebaseAuth.instance.signOut();

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      // ✅ fallback cuando llegaste con go()
      context.go('/home'); 
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncCats = ref.watch(categoriesProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Categorías'),
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => _handleBack(context),
              tooltip: 'Volver',
            ),
            actions: [
              IconButton(
                tooltip: 'Locales',
                icon: const Icon(Icons.store),
                onPressed: () => context.push('/stores'),
              ),
              IconButton(
                tooltip: 'Refrescar',
                icon: const Icon(Icons.refresh),
                onPressed: () => ref.invalidate(categoriesProvider),
              ),
              IconButton(
                tooltip: 'Cerrar sesión',
                icon: const Icon(Icons.logout),
                onPressed: _signOut,
              ),
              const CartIconButton(),
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
                  hintText: 'Buscar categorías…',
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
            sliver: asyncCats.when(
              data: (cats) {
                if (cats.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _EmptyState(
                      title: 'No hay categorías',
                      subtitle: 'Revisa el backend o refresca para cargar datos.',
                      buttonText: 'Refrescar',
                      onPressed: () => ref.invalidate(categoriesProvider),
                      icon: Icons.category_outlined,
                    ),
                  );
                }

                final filtered = cats.where((c) {
                  if (_q.isEmpty) return true;
                  return c.name.toLowerCase().contains(_q);
                }).toList();

                if (filtered.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _EmptyState(
                      title: 'Sin resultados',
                      subtitle: 'No encontramos categorías con “$_q”.',
                      buttonText: 'Limpiar búsqueda',
                      onPressed: () => setState(() => _q = ''),
                      icon: Icons.search_off,
                    ),
                  );
                }

                // ✅ Grid bonito
                return SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final c = filtered[i];
                      final icon = (c.icon == null || c.icon!.trim().isEmpty) ? '🍽️' : c.icon!;
                      return _CategoryCard(
                        emoji: icon,
                        name: c.name,
                        onTap: () => context.push('/products/${c.id}?name=${Uri.encodeComponent(c.name)}'),
                      );
                    },
                    childCount: filtered.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.15,
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(child: _CategoriesSkeleton()),
              error: (e, st) {
                debugPrint('ERROR categoriesProvider: $e');
                debugPrintStack(stackTrace: st);
                return SliverToBoxAdapter(
                  child: _ErrorState(
                    message: e.toString(),
                    onRetry: () => ref.invalidate(categoriesProvider),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.emoji,
    required this.name,
    required this.onTap,
  });

  final String emoji;
  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // “icon bubble”
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const Spacer(),
            Row(
              children: [
                Text(
                  'Ver productos',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: scheme.primary, fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right, color: scheme.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoriesSkeleton extends StatelessWidget {
  const _CategoriesSkeleton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget box({required double h, double? w}) => Container(
          height: h,
          width: w,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
        );

    return Column(
      children: [
        const SizedBox(height: 6),
        GridView.builder(
          itemCount: 6,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.15,
          ),
          itemBuilder: (_, __) {
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  box(h: 44, w: 44),
                  const SizedBox(height: 12),
                  box(h: 14, w: 120),
                  const SizedBox(height: 8),
                  box(h: 14, w: 90),
                  const Spacer(),
                  box(h: 14, w: 110),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onPressed,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onPressed;
  final IconData icon;

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
            'Error cargando categorías',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: scheme.onErrorContainer),
          ),
          const SizedBox(height: 6),
          Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onErrorContainer)),
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
