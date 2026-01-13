import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/order_tracking_providers.dart';

class OrderTrackingPage extends ConsumerWidget {
  const OrderTrackingPage({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncOrder = ref.watch(orderLiveProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracking del pedido'),
        actions: [
          IconButton(
            tooltip: 'Refrescar',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(orderLiveProvider(orderId)),
          ),
        ],
      ),
      body: asyncOrder.when(
        data: (o) {
          final status = (o['status'] ?? '').toString();
          final tracking = (o['tracking'] is List) ? (o['tracking'] as List) : const [];

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(orderLiveProvider(orderId)),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _HeaderCard(orderId: orderId, status: status, total: _readTotal(o)),
                const SizedBox(height: 12),

                const Text('Estados', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),

                if (tracking.isEmpty)
                  const Text('Aún no hay eventos de tracking.')
                else
                  ...tracking.reversed.map((t) {
                    final m = Map<String, dynamic>.from(t as Map);
                    final s = (m['status'] ?? '').toString();
                    final ts = (m['timestamp'] ?? '').toString();
                    return Card(
                      child: ListTile(
                        leading: Icon(_iconForStatus(s)),
                        title: Text(s),
                        subtitle: Text(ts),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error cargando tracking:\n$e'),
          ),
        ),
      ),
    );
  }

  double _readTotal(Map<String, dynamic> o) {
    final totals = o['totals'];
    if (totals is Map && totals['total'] != null) return (totals['total'] as num).toDouble();
    if (o['total'] != null) return (o['total'] as num).toDouble();
    return 0;
  }

  static IconData _iconForStatus(String s) {
    switch (s) {
      case 'CREATED':
        return Icons.receipt_long;
      case 'PREPARING':
        return Icons.kitchen;
      case 'READY':
        return Icons.check_circle_outline;
      case 'DELIVERED':
        return Icons.delivery_dining;
      case 'CANCELLED':
        return Icons.cancel_outlined;
      default:
        return Icons.circle_outlined;
    }
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.orderId, required this.status, required this.total});

  final String orderId;
  final String status;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Pedido $orderId', style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('Estado: $status'),
              ]),
            ),
            Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
