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

  @override
  void dispose() {
    _couponCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final cartCtrl = ref.read(cartProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrito'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/categories'),
        ),
      ),
      body: cart.items.isEmpty
          ? const Center(child: Text('Tu carrito está vacío'))
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                ...cart.items.map((i) => Card(
                      child: ListTile(
                        title: Text(i.nameSnapshot),
                        subtitle: Text('Unit: \$${i.priceSnapshot.toStringAsFixed(2)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.remove), onPressed: () => cartCtrl.dec(i.productId)),
                            Text('${i.qty}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(icon: const Icon(Icons.add), onPressed: () => cartCtrl.inc(i.productId)),
                          ],
                        ),
                      ),
                    )),
                const SizedBox(height: 12),

                // CUPÓN
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Cupón', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _couponCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Ej: PROMO10',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                onPressed: () async {
                                  final code = _couponCtrl.text.trim();
                                  if (code.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Ingresa un código de cupón')),
                                    );
                                    return;
                                  }

                                  try {
                                    final ds = ref.read(couponsRemoteDsProvider);
                                    final res = await ds.validateCoupon(code: code, subtotal: cart.subtotal);

                                    if (!res.valid || res.discountAmount <= 0) {
                                      cartCtrl.clearCoupon();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Cupón inválido o sin descuento')),
                                      );
                                      return;
                                    }

                                    cartCtrl.applyCouponResult(
                                      code: res.code ?? code,
                                      discountAmount: res.discountAmount,
                                    );

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Cupón aplicado. Descuento: \$${res.discountAmount.toStringAsFixed(2)}')),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error validando cupón: $e')),
                                    );
                                  }
                                },
                                child: const Text('Aplicar'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton(
                              onPressed: () {
                                cartCtrl.clearCoupon();
                                _couponCtrl.clear();
                              },
                              child: const Text('Quitar'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // RESUMEN
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _row('Subtotal', '\$${cart.subtotal.toStringAsFixed(2)}'),
                        _row('Descuento', '- \$${cart.discountAmount.toStringAsFixed(2)}'),
                        const Divider(),
                        _row('Total', '\$${cart.total.toStringAsFixed(2)}', bold: true),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => context.push('/pay'),
                          child: const Text('Continuar a pagar'),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    final style = bold ? const TextStyle(fontWeight: FontWeight.bold) : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}
