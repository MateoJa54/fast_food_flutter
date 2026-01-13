import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/recommendations_providers.dart';

class RecommendationsPage extends ConsumerWidget {
  const RecommendationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRec = ref.watch(recommendationsProvider(12));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recomendaciones IA'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      body: asyncRec.when(
        data: (json) {
          final list = (json['recommendations'] is List) ? (json['recommendations'] as List) : const [];
          if (list.isEmpty) return const Center(child: Text('No hay recomendaciones por ahora.'));

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final r = Map<String, dynamic>.from(list[index] as Map);
              final id = (r['productId'] ?? '').toString();
              final name = (r['name'] ?? 'Producto').toString();
              final price = (r['basePrice'] is num) ? (r['basePrice'] as num).toDouble() : 0.0;
              final score = (r['score'] is num) ? (r['score'] as num).toDouble() : 0.0;

              return Card(
                child: ListTile(
                  title: Text(name),
                  subtitle: Text('Score: ${score.toStringAsFixed(0)}'),
                  trailing: Text('\$${price.toStringAsFixed(2)}'),
                  onTap: id.isEmpty ? null : () => context.push('/product/$id'),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error cargando recomendaciones:\n$e'),
        )),
      ),
    );
  }
}
