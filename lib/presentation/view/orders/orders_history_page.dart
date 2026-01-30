import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/orders_providers.dart';

class OrdersHistoryPage extends ConsumerWidget {
  const OrdersHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncOrders = ref.watch(myOrdersProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Mis pedidos'),
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.canPop() ? context.pop() : context.go('/categories'),
            ),
            actions: [
              IconButton(
                tooltip: 'Refrescar',
                icon: const Icon(Icons.refresh),
                onPressed: () => ref.invalidate(myOrdersProvider),
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
            sliver: asyncOrders.when(
              data: (orders) {
                if (orders.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _EmptyOrders(
                      onOrderNow: () => context.go('/categories'),
                    ),
                  );
                }

                final normalized = orders
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList();

                // Ordenar por createdAt (si viene como timestamp/string)
                normalized.sort((a, b) {
                  final da = _parseDate(a['createdAt']);
                  final db = _parseDate(b['createdAt']);
                  return db.compareTo(da);
                });

                // Si hay alguno activo (no entregado/cancelado), lo mostramos arriba
                final active = normalized.firstWhere(
                  (o) => _isActiveStatus((o['status'] ?? '').toString()),
                  orElse: () => const {},
                );

                return SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      if (active.isNotEmpty) ...[
                        Text(
                          'En progreso',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 10),
                        _OrderCard(
                          order: active,
                          highlight: true,
                          onTap: () {
                            final id = _readId(active);
                            if (id.isNotEmpty) context.push('/orders/$id');
                          },
                        ),
                        const SizedBox(height: 18),
                      ],

                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Historial',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${normalized.length} pedidos',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      ...normalized.map((o) {
                        // Evita duplicar el activo si ya lo mostramos arriba
                        if (active.isNotEmpty && _readId(o) == _readId(active)) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _OrderCard(
                            order: o,
                            onTap: () {
                              final id = _readId(o);
                              if (id.isNotEmpty) context.push('/orders/$id');
                            },
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(child: _OrdersSkeleton()),
              error: (e, _) => SliverToBoxAdapter(
                child: _ErrorState(
                  message: 'Error cargando pedidos:\n$e',
                  onRetry: () => ref.invalidate(myOrdersProvider),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: asyncOrders.maybeWhen(
        data: (orders) => orders.isEmpty
            ? null
            : FloatingActionButton.extended(
                onPressed: () => context.go('/categories'),
                icon: const Icon(Icons.fastfood),
                label: const Text('Ordenar'),
              ),
        orElse: () => null,
      ),
    );
  }

  // ---------------- helpers ----------------

  static String _readId(Map<String, dynamic> o) {
    return (o['id'] ?? o['orderId'] ?? '').toString();
  }

  static double _readTotal(Map<String, dynamic> o) {
    final totals = o['totals'];
    if (totals is Map && totals['total'] != null) {
      return (totals['total'] as num).toDouble();
    }
    if (o['total'] != null) {
      return (o['total'] as num).toDouble();
    }
    return 0;
  }

  static String _readDeliveryMode(Map<String, dynamic> o) {
    final mode = (o['deliveryMode'] ?? '').toString();
    if (mode.isEmpty) return '';
    return mode.toUpperCase();
  }

  static DateTime _parseDate(dynamic raw) {
    if (raw == null) return DateTime.fromMillisecondsSinceEpoch(0);

    // Firestore timestamp suele venir como {seconds:..., nanoseconds:...} o string
    if (raw is Map && raw['seconds'] is num) {
      final seconds = (raw['seconds'] as num).toInt();
      return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    }
    if (raw is String) {
      // ISO string típico
      final dt = DateTime.tryParse(raw);
      return dt ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static String _formatDate(dynamic raw) {
    final dt = _parseDate(raw);
    if (dt.millisecondsSinceEpoch == 0) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
  }

  static bool _isActiveStatus(String status) {
    final s = status.toUpperCase();
    return !(s.contains('DELIVER') || s.contains('COMPLET') || s.contains('CANCEL') || s.contains('REJECT'));
  }
}

// ---------------- UI components ----------------

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.onTap,
    this.highlight = false,
  });

  final Map<String, dynamic> order;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final id = (order['id'] ?? order['orderId'] ?? '').toString();
    final shortId = id.isEmpty ? '—' : (id.length <= 8 ? id : id.substring(0, 8).toUpperCase());
    final status = (order['status'] ?? '').toString();
    final total = OrdersHistoryPage._readTotal(order);
    final mode = OrdersHistoryPage._readDeliveryMode(order);
    final date = OrdersHistoryPage._formatDate(order['createdAt']);

    final statusUi = _statusStyle(context, status);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: highlight ? scheme.primaryContainer : scheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.15)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icono / “avatar” del pedido
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: highlight ? scheme.onPrimaryContainer.withOpacity(0.08) : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                highlight ? Icons.local_shipping : Icons.receipt_long,
                color: highlight ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Linea 1: Pedido + badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Pedido #$shortId',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: highlight ? scheme.onPrimaryContainer : null,
                              ),
                        ),
                      ),
                      _StatusPill(
                        label: statusUi.label,
                        bg: highlight ? statusUi.bg.withOpacity(0.20) : statusUi.bg,
                        fg: highlight ? scheme.onPrimaryContainer : statusUi.fg,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Linea 2: modo + fecha
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (mode.isNotEmpty)
                        _MiniChip(
                          text: mode == 'PICKUP' ? 'PICKUP' : 'DELIVERY',
                          icon: mode == 'PICKUP' ? Icons.store : Icons.location_on,
                          highlight: highlight,
                        ),
                      if (date.isNotEmpty)
                        _MiniChip(
                          text: date,
                          icon: Icons.schedule,
                          highlight: highlight,
                        ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Total
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: highlight ? scheme.onPrimaryContainer : scheme.primary,
                        ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: highlight ? scheme.onPrimaryContainer : scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  _StatusStyle _statusStyle(BuildContext context, String status) {
    final scheme = Theme.of(context).colorScheme;
    final s = status.toUpperCase();

    // Ajusta a tus estados reales si quieres
    if (s.contains('APPROV') || s.contains('PAID')) {
      return _StatusStyle('Pagado', scheme.tertiaryContainer, scheme.onTertiaryContainer);
    }
    if (s.contains('READY')) {
      return _StatusStyle('Listo', scheme.secondaryContainer, scheme.onSecondaryContainer);
    }
    if (s.contains('PREPAR') || s.contains('COOK')) {
      return _StatusStyle('Preparando', scheme.primaryContainer, scheme.onPrimaryContainer);
    }
    if (s.contains('CANCEL')) {
      return _StatusStyle('Cancelado', scheme.errorContainer, scheme.onErrorContainer);
    }
    if (s.contains('REJECT')) {
      return _StatusStyle('Rechazado', scheme.errorContainer, scheme.onErrorContainer);
    }
    if (s.isEmpty) {
      return _StatusStyle('Estado', scheme.surfaceContainerHighest, scheme.onSurfaceVariant);
    }
    return _StatusStyle(status, scheme.surfaceContainerHighest, scheme.onSurfaceVariant);
  }
}

class _StatusStyle {
  final String label;
  final Color bg;
  final Color fg;
  _StatusStyle(this.label, this.bg, this.fg);
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.bg, required this.fg});
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w900, color: fg),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({
    required this.text,
    required this.icon,
    required this.highlight,
  });

  final String text;
  final IconData icon;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = highlight ? scheme.onPrimaryContainer.withOpacity(0.10) : scheme.surfaceContainerHighest;
    final fg = highlight ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders({required this.onOrderNow});
  final VoidCallback onOrderNow;

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
          Icon(Icons.receipt_long, size: 56, color: scheme.onSurfaceVariant),
          const SizedBox(height: 10),
          Text(
            'Aún no tienes pedidos',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'Cuando hagas tu primer pedido, lo verás aquí con su tracking.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onOrderNow,
            icon: const Icon(Icons.fastfood),
            label: const Text('Ordenar ahora'),
          ),
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

class _OrdersSkeleton extends StatelessWidget {
  const _OrdersSkeleton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget box({double? w, required double h}) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        box(w: 140, h: 18),
        const SizedBox(height: 12),
        ...List.generate(
          4,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  box(w: 44, h: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        box(w: 180, h: 14),
                        const SizedBox(height: 8),
                        box(w: 120, h: 12),
                        const SizedBox(height: 10),
                        box(w: 90, h: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
