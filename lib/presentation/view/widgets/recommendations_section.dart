import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/recommendations_providers.dart';

class RecommendationsSection extends ConsumerWidget {
  const RecommendationsSection({super.key, this.limit = 5});
  final int limit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRec = ref.watch(recommendationsProvider(limit));

    return asyncRec.when(
      data: (json) {
        final contextLabel = (json['context'] ?? '').toString();
        final list = (json['recommendations'] is List) ? (json['recommendations'] as List) : const [];

        if (list.isEmpty) {
          return const SizedBox(); // no ensuciar el Home si no hay nada
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Para ti',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
                if (contextLabel.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    child: Text(contextLabel, style: const TextStyle(fontSize: 12)),
                  ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => context.push('/recommendations'),
                  child: const Text('Ver más'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            SizedBox(
              height: 170,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final r = Map<String, dynamic>.from(list[index] as Map);
                  final id = (r['productId'] ?? '').toString();
                  final name = (r['name'] ?? 'Producto').toString();
                  final price = (r['basePrice'] is num) ? (r['basePrice'] as num).toDouble() : 0.0;
                  final score = (r['score'] is num) ? (r['score'] as num).toDouble() : 0.0;

                  // reason opcional
                  final reason = (r['reason'] is Map) ? Map<String, dynamic>.from(r['reason'] as Map) : null;
                  final contentScore = reason?['contentScore'];
                  final contextBoost = reason?['contextBoost'];

                  return InkWell(
                    onTap: id.isEmpty ? null : () => context.push('/product/$id'),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 220,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.auto_awesome, size: 18),
                              SizedBox(width: 6),
                              Text('Recomendado', style: TextStyle(fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(name, maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 8),
                          Text('\$${price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                          const Spacer(),
                          Text('Score: ${score.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12)),
                          if (contentScore != null || contextBoost != null)
                            Text(
                              'Razón: content=${contentScore ?? "-"} context=${contextBoost ?? "-"}',
                              style: const TextStyle(fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text('Error recomendaciones: $e'),
      ),
    );
  }
}
