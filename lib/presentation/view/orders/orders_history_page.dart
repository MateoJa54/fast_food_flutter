import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/orders_providers.dart';

class OrdersHistoryPage extends ConsumerWidget {
  const OrdersHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncOrders = ref.watch(myOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis pedidos'),
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
      body: asyncOrders.when(
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Aún no tienes pedidos.'),
              ),
            );
          }

          // Esperamos que cada order sea Map con id/status/createdAt/totals
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final o = Map<String, dynamic>.from(orders[index] as Map);
              final id = (o['id'] ?? o['orderId'] ?? '').toString();
              final status = (o['status'] ?? '').toString();

              // totals.total puede estar anidado o total directo
              final total = _readTotal(o);

              final createdAt = (o['createdAt'] ?? '').toString();

              return Card(
                child: ListTile(
                  title: Text('Pedido $id'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Estado: $status'),
                      if (createdAt.isNotEmpty) Text('Fecha: $createdAt'),
                    ],
                  ),
                  trailing: Text('\$${total.toStringAsFixed(2)}'),
                  onTap: () {
                    // abre tracking
                    if (id.isNotEmpty) context.push('/orders/$id');
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error cargando pedidos:\n$e'),
          ),
        ),
      ),
    );
  }

  double _readTotal(Map<String, dynamic> o) {
    final totals = o['totals'];
    if (totals is Map && totals['total'] != null) {
      return (totals['total'] as num).toDouble();
    }
    if (o['total'] != null) {
      return (o['total'] as num).toDouble();
    }
    return 0;
  }
}
