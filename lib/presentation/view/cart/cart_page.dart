import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/cart_providers.dart';
import '../../providers/coupons_providers.dart';

class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  final _couponCtrl = TextEditingController();
  bool _applying = false;

  @override
  void dispose() {
    _couponCtrl.dispose();
    super.dispose();
  }

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/categories');
    }
  }

  Future<void> _applyCoupon() async {
    final cart = ref.read(cartProvider);
    final cartCtrl = ref.read(cartProvider.notifier);

    final code = _couponCtrl.text.trim();
    if (code.isEmpty) {
      _toast('Ingresa un código de cupón');
      return;
    }
    if (cart.subtotal <= 0) {
      _toast('Agrega productos antes de aplicar cupón');
      return;
    }

    setState(() => _applying = true);
    try {
      final ds = ref.read(couponsRemoteDsProvider);
      final res = await ds.validateCoupon(code: code, subtotal: cart.subtotal);

      if (!res.valid || res.discountAmount <= 0) {
        cartCtrl.clearCoupon();
        _toast('Cupón inválido o sin descuento');
        return;
      }

      cartCtrl.applyCouponResult(
        code: res.code ?? code,
        discountAmount: res.discountAmount,
      );

      _toast('Cupón aplicado: -\$${res.discountAmount.toStringAsFixed(2)}');
    } catch (e) {
      _toast('Error validando cupón: $e');
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  void _removeCoupon() {
    final cartCtrl = ref.read(cartProvider.notifier);
    cartCtrl.clearCoupon();
    _couponCtrl.clear();
    _toast('Cupón removido');
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          content: Text(msg),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final cartCtrl = ref.read(cartProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    final isEmpty = cart.items.isEmpty;

    // Si tu provider ya guarda couponCode, puedes precargarlo:
    // if (_couponCtrl.text.isEmpty && (cart.couponCode ?? '').isNotEmpty) _couponCtrl.text = cart.couponCode!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Carrito'),
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => _handleBack(context),
              tooltip: 'Volver',
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
            sliver: isEmpty
                ? SliverToBoxAdapter(
                    child: _EmptyCart(
                      onOrderNow: () => context.go('/categories'),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        // Items
                        Text(
                          'Tu pedido',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 10),

                        ...cart.items.map((i) {
                          final lineTotal = i.priceSnapshot * i.qty;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _CartItemCard(
                              title: i.nameSnapshot,
                              unitPrice: i.priceSnapshot,
                              qty: i.qty,
                              lineTotal: lineTotal,
                              onDec: () => cartCtrl.dec(i.productId),
                              onInc: () => cartCtrl.inc(i.productId),
                              onRemove: () {
                                // opción rápida: bajar a 0 con dec repetido no es UX.
                                // Si tienes remove(productId), úsalo aquí.
                                // Si no, hacemos dec hasta 0 (simple).
                                for (int k = 0; k < i.qty; k++) {
                                  cartCtrl.dec(i.productId);
                                }
                              },
                            ),
                          );
                        }).toList(),

                        const SizedBox(height: 6),

                        // Cupón
                        _CouponCard(
                          controller: _couponCtrl,
                          applying: _applying,
                          hasCouponApplied: (cart.discountAmount > 0),
                          onApply: _applyCoupon,
                          onRemove: _removeCoupon,
                        ),

                        const SizedBox(height: 12),

                        // Totales (card visual) — el checkout real está abajo fijo
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.15)),
                          ),
                          child: Column(
                            children: [
                              _moneyRow(context, 'Subtotal', cart.subtotal),
                              const SizedBox(height: 6),
                              _moneyRow(context, 'Descuento', -cart.discountAmount, negative: true),
                              const Divider(height: 20),
                              _moneyRow(context, 'Total', cart.total, big: true),
                            ],
                          ),
                        ),

                        const SizedBox(height: 90), // espacio para el bottom bar
                      ],
                    ),
                  ),
          ),
        ],
      ),

      // ✅ Bottom checkout sticky
      bottomNavigationBar: isEmpty
          ? null
          : SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.15))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant)),
                          const SizedBox(height: 2),
                          Text(
                            '\$${cart.total.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: cart.total <= 0 ? null : () => context.push('/pay'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Continuar'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _moneyRow(BuildContext context, String label, double value, {bool big = false, bool negative = false}) {
    final scheme = Theme.of(context).colorScheme;
    final txt = '\$${value.abs().toStringAsFixed(2)}';
    final sign = negative && value != 0 ? '-' : '';
    final style = big
        ? Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)
        : Theme.of(context).textTheme.bodyMedium;

    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(
          '$sign$txt',
          style: style?.copyWith(
            color: negative ? scheme.tertiary : null,
            fontWeight: big ? FontWeight.w900 : null,
          ),
        ),
      ],
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.title,
    required this.unitPrice,
    required this.qty,
    required this.lineTotal,
    required this.onDec,
    required this.onInc,
    required this.onRemove,
  });

  final String title;
  final double unitPrice;
  final int qty;
  final double lineTotal;
  final VoidCallback onDec;
  final VoidCallback onInc;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // “imagen” placeholder (luego lo conectas a product.imageUrl)
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 64,
              height: 64,
              color: scheme.surfaceContainerHighest,
              alignment: Alignment.center,
              child: Icon(Icons.fastfood, color: scheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Quitar',
                      onPressed: onRemove,
                      icon: const Icon(Icons.close),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                Text(
                  'Unit: \$${unitPrice.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    _QtyStepper(qty: qty, onDec: onDec, onInc: onInc),
                    const Spacer(),
                    Text(
                      '\$${lineTotal.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.qty,
    required this.onDec,
    required this.onInc,
  });

  final int qty;
  final VoidCallback onDec;
  final VoidCallback onInc;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onDec,
            icon: const Icon(Icons.remove),
            visualDensity: VisualDensity.compact,
            tooltip: 'Reducir',
          ),
          Text(
            '$qty',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          IconButton(
            onPressed: onInc,
            icon: const Icon(Icons.add),
            visualDensity: VisualDensity.compact,
            tooltip: 'Aumentar',
          ),
        ],
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  const _CouponCard({
    required this.controller,
    required this.applying,
    required this.hasCouponApplied,
    required this.onApply,
    required this.onRemove,
  });

  final TextEditingController controller;
  final bool applying;
  final bool hasCouponApplied;
  final VoidCallback onApply;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.local_offer, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cupón',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              if (hasCouponApplied)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: scheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('Aplicado', style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w900)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: 'Ej: PROMO10',
              filled: true,
              fillColor: scheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: applying ? null : onApply,
                  child: applying
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Aplicar'),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: onRemove,
                child: const Text('Quitar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart({required this.onOrderNow});
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
          Icon(Icons.shopping_cart_outlined, size: 56, color: scheme.onSurfaceVariant),
          const SizedBox(height: 10),
          Text(
            'Tu carrito está vacío',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'Agrega productos del menú para continuar.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onOrderNow,
            icon: const Icon(Icons.fastfood),
            label: const Text('Ir a categorías'),
          ),
        ],
      ),
    );
  }
}
