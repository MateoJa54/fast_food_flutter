import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/recommendations_providers.dart';

class RecommendationsSection extends ConsumerWidget {
  const RecommendationsSection({super.key, this.limit = 5});
  final int limit;

  static const double kRecItemHeight = 240; // ✅ un poco más alto
  static const double kRecItemWidth = 240;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRec = ref.watch(recommendationsProvider(limit));
    final scheme = Theme.of(context).colorScheme;

    return asyncRec.when(
      data: (json) {
        final contextLabel = (json['context'] ?? '').toString();
        final list = (json['recommendations'] is List) ? (json['recommendations'] as List) : const [];

        if (list.isEmpty) return const SizedBox();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Para ti',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                if (contextLabel.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: scheme.surfaceContainerHighest,
                    ),
                    child: Text(contextLabel, style: Theme.of(context).textTheme.labelMedium),
                  ),
                const SizedBox(width: 6),
                TextButton(
                  onPressed: () => context.push('/recommendations'),
                  child: const Text('Ver más'),
                ),
              ],
            ),
            const SizedBox(height: 10),

            SizedBox(
              height: kRecItemHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final r = Map<String, dynamic>.from(list[index] as Map);
                  final id = (r['productId'] ?? '').toString();
                  final name = (r['name'] ?? 'Producto').toString();
                  final price = (r['basePrice'] is num) ? (r['basePrice'] as num).toDouble() : 0.0;
                  final tags = (r['tags'] is List) ? (r['tags'] as List).map((e) => e.toString()).toList() : <String>[];

                  final reason = (r['reason'] is Map) ? Map<String, dynamic>.from(r['reason'] as Map) : null;
                  final hint = _humanReason(reason);

                  return SizedBox( // ✅ ERA _SizedBox
                    width: kRecItemWidth,
                    height: kRecItemHeight,
                    child: _RecCard(
                      name: name,
                      price: price,
                      tags: tags,
                      hint: hint,
                      onTap: id.isEmpty ? null : () => context.push('/product/$id'),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const _RecSkeleton(),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text('Error recomendaciones: $e'),
      ),
    );
  }

  String _humanReason(Map<String, dynamic>? reason) {
    if (reason == null) return 'Recomendado para ti';
    final contextBoost = reason['contextBoost'];
    final contentScore = reason['contentScore'];

    if (contextBoost is num && contextBoost > 0) return 'Ideal para este momento';
    if (contentScore is num && contentScore > 0) return 'Basado en tus gustos';
    return 'Recomendado para ti';
  }
}

class _RecCard extends StatelessWidget {
  const _RecCard({
    required this.name,
    required this.price,
    required this.tags,
    required this.hint,
    required this.onTap,
  });

  final String name;
  final double price;
  final List<String> tags;
  final String hint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, c) {
        final imageH = (c.maxHeight * 0.34).clamp(64.0, 80.0); // ✅ un pelín menor
        final tagsH = tags.isEmpty ? 0.0 : 24.0; // ✅ reduce 2px

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    height: imageH,
                    width: double.infinity,
                    color: scheme.surfaceContainerHighest,
                    alignment: Alignment.center,
                    child: Icon(Icons.fastfood, size: 32, color: scheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(height: 6),

                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),

                Text(
                  '\$${price.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),

                if (tagsH > 0)
                  SizedBox(
                    height: tagsH,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: tags.take(3).length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (_, i) {
                        final t = tags[i];
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(t, style: Theme.of(context).textTheme.labelSmall),
                        );
                      },
                    ),
                  ),

                const Spacer(),

                Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 16, color: scheme.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        hint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                      onPressed: onTap,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Ver'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RecSkeleton extends StatelessWidget {
  const _RecSkeleton();

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
        Row(
          children: [
            Expanded(child: box(h: 18)),
            const SizedBox(width: 10),
            box(w: 60, h: 18),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: RecommendationsSection.kRecItemHeight, // ✅ consistente
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, __) => Container(
              width: RecommendationsSection.kRecItemWidth,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  box(h: 80),
                  const SizedBox(height: 8),
                  box(w: 160, h: 14),
                  const SizedBox(height: 8),
                  box(w: 90, h: 14),
                  const Spacer(),
                  box(h: 30),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
