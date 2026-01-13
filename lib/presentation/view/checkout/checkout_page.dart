import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/cart_providers.dart';
import '../../providers/checkout_providers.dart';
import '../../providers/stores_providers.dart';

class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  String deliveryMode = 'PICKUP'; // PICKUP / DELIVERY
  String? selectedStoreId;
  final addressCtrl = TextEditingController();

  bool loading = false;

  @override
  void dispose() {
    addressCtrl.dispose();
    super.dispose();
  }

  String _clientOrderId() {
    // simple uuid-like local (suficiente para idempotencia en demo)
    final rnd = Random().nextInt(999999);
    return 'client-${DateTime.now().millisecondsSinceEpoch}-$rnd';
    // Si luego quieres: usa paquete uuid
  }

  Future<void> _payAndCreateOrder(BuildContext context) async {
    final cart = ref.read(cartProvider);
    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tu carrito está vacío')),
      );
      return;
    }

    if (deliveryMode == 'PICKUP' && (selectedStoreId == null || selectedStoreId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una tienda para Pickup')),
      );
      return;
    }

    if (deliveryMode == 'DELIVERY' && addressCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa una dirección para Delivery')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final payments = ref.read(paymentsRemoteDsProvider);
      final orders = ref.read(ordersRemoteDsProvider);

      // 1) Simular pago
      final payRes = await payments.simulatePayment(amount: cart.total);
      final success = (payRes['success'] ?? false) as bool;

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(payRes['message']?.toString() ?? 'Pago rechazado')),
        );
        setState(() => loading = false);
        return;
      }

      // 2) Crear pedido (payload según tu backend)
      final payload = {
        'clientOrderId': _clientOrderId(),
        'items': cart.items.map((i) => {
              'productId': i.productId,
              'qty': i.qty,
              'nameSnapshot': i.nameSnapshot,
              'priceSnapshot': i.priceSnapshot,
              'tagsSnapshot': i.tagsSnapshot,
              'notes': i.notes,
              'modifiersSnapshot': i.modifiersSnapshot,
            }).toList(),
        'deliveryMode': deliveryMode,
        'storeId': deliveryMode == 'PICKUP' ? selectedStoreId : null,
        'addressSnapshot': deliveryMode == 'DELIVERY'
            ? {
                'addressLine': addressCtrl.text.trim(),
              }
            : null,
        'couponSnapshot': cart.couponCode == null
            ? null
            : {
                'code': cart.couponCode,
                'discountAmount': cart.discountAmount,
              },
        'totals': {
          'subtotal': cart.subtotal,
          'discountTotal': cart.discountAmount,
          'total': cart.total,
        },
        // persistimos pago simulado
        'payment': {
          'status': 'SIMULATED_APPROVED',
          'method': 'CARD',
          'transactionId': payRes['transactionId'] ?? '',
          'paidAt': DateTime.now().toIso8601String(),
        },
      };

      final orderRes = await orders.createOrder(payload);
      final orderId = (orderRes['orderId'] ?? '').toString();

      if (orderId.isEmpty) {
        throw Exception('No se recibió orderId del backend');
      }

      // 3) Limpiar carrito y navegar a tracking
      ref.read(cartProvider.notifier).clear();

      if (mounted) {
        context.go('/orders/$orderId');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error en checkout: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final storesAsync = ref.watch(storesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/cart'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Resumen', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _row('Subtotal', '\$${cart.subtotal.toStringAsFixed(2)}'),
                  _row('Descuento', '- \$${cart.discountAmount.toStringAsFixed(2)}'),
                  const Divider(),
                  _row('Total', '\$${cart.total.toStringAsFixed(2)}', bold: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Entrega', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),

                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'PICKUP', label: Text('Pickup')),
                      ButtonSegment(value: 'DELIVERY', label: Text('Delivery')),
                    ],
                    selected: {deliveryMode},
                    onSelectionChanged: (s) {
                      setState(() => deliveryMode = s.first);
                    },
                  ),

                  const SizedBox(height: 12),

                  if (deliveryMode == 'PICKUP')
                    storesAsync.when(
                      data: (stores) {
                        if (stores.isEmpty) return const Text('No hay tiendas disponibles.');

                        selectedStoreId ??= stores.first.id;

                        return DropdownButtonFormField<String>(
                          value: selectedStoreId,
                          items: stores
                              .map((s) => DropdownMenuItem(
                                    value: s.id,
                                    child: Text(s.name),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => selectedStoreId = v),
                          decoration: const InputDecoration(
                            labelText: 'Tienda',
                            border: OutlineInputBorder(),
                          ),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text('Error tiendas: $e'),
                    ),

                  if (deliveryMode == 'DELIVERY') ...[
                    TextField(
                      controller: addressCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Dirección',
                        border: OutlineInputBorder(),
                      ),
                      minLines: 1,
                      maxLines: 3,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: loading ? null : () => _payAndCreateOrder(context),
              child: loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator())
                  : const Text('Pagar y crear pedido'),
            ),
          ),
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
