import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/cart_providers.dart';
import '../../providers/checkout_providers.dart';
import '../../providers/payment_providers.dart';
import '../../providers/stores_providers.dart';

class CreateOrderPage extends ConsumerStatefulWidget {
  const CreateOrderPage({super.key});

  @override
  ConsumerState<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends ConsumerState<CreateOrderPage> {
  String deliveryMode = 'PICKUP';
  String? selectedStoreId;

  final addressCtrl = TextEditingController();
  
  double? deliveryLat;
  double? deliveryLong;

  bool loading = false;

  @override
  void dispose() {
    addressCtrl.dispose();
    super.dispose();
  }

  String _clientOrderId() {
    final rnd = Random().nextInt(999999);
    return 'client-${DateTime.now().millisecondsSinceEpoch}-$rnd';
  }

  Future<void> _createOrder() async {
    final cart = ref.read(cartProvider);
    final payment = ref.read(paymentResultProvider);

    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Carrito vacío')));
      return;
    }

    if (payment == null || !payment.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero realiza un pago aprobado')),
      );
      return;
    }

    // Validaciones entrega
    if (deliveryMode == 'PICKUP') {
      if (selectedStoreId == null || selectedStoreId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona una tienda')));
        return;
      }
    } else {
      if (addressCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa una dirección')));
        return;
      }
      deliveryLat ??= -0.3345;
      deliveryLong ??= -78.4421;
    }

    setState(() => loading = true);

    try {
      final orders = ref.read(ordersRemoteDsProvider);

      // PAYLOAD REAL: /orders usa paymentTransactionId, NO payment object
      final payload = <String, dynamic>{
        'clientOrderId': _clientOrderId(),
        'items': cart.items.map((i) => {
              'productId': i.productId,
              'qty': i.qty,
              'nameSnapshot': i.nameSnapshot,
              'priceSnapshot': i.priceSnapshot,
              'tagsSnapshot': i.tagsSnapshot,
              if (i.notes != null && i.notes!.trim().isNotEmpty) 'notes': i.notes!.trim(),
              if (i.modifiersSnapshot.isNotEmpty) 'modifiersSnapshot': i.modifiersSnapshot,
            }).toList(),
        'deliveryMode': deliveryMode,
        'totals': {
          'subtotal': cart.subtotal,
          'discountTotal': cart.discountAmount,
          'total': cart.total,
        },
        'paymentTransactionId': payment.transactionId,
      };

      // ✅ storeId SOLO si PICKUP (en DELIVERY no lo mandes, por eso te fallaba)
      if (deliveryMode == 'PICKUP') {
        payload['storeId'] = selectedStoreId!;
      }

      // ✅ addressSnapshot SOLO si DELIVERY (si tu backend lo soporta)
      if (deliveryMode == 'DELIVERY') {
        payload['addressSnapshot'] = {
          'line1': addressCtrl.text.trim(),
          'lat': deliveryLat ?? -0.3345,
          'long': deliveryLong ?? -78.4421,
        };
      }

      // ✅ couponSnapshot solo si existe
      if (cart.couponCode != null && cart.couponCode!.trim().isNotEmpty) {
        payload['couponSnapshot'] = {
          'code': cart.couponCode,
          'discountAmount': cart.discountAmount,
        };
      }

      final res = await orders.createOrder(payload);
      final orderId = (res['orderId'] ?? '').toString();
      if (orderId.isEmpty) throw Exception('No se recibió orderId');

      // Limpieza
      ref.read(cartProvider.notifier).clear();
      ref.read(paymentResultProvider.notifier).state = null;

      if (mounted) context.go('/orders/$orderId');
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        debugPrint('STATUS: ${e.response?.statusCode}');
        debugPrint('DATA: $data');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creando orden: $data')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creando orden: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final payment = ref.watch(paymentResultProvider);
    final storesAsync = ref.watch(storesProvider);
    final cart = ref.watch(cartProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Orden'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/pay'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (payment != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pago aprobado',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text('TX: ${payment.transactionId}'),
                    Text('Método: ${payment.method}'),
                    Text('Monto: \$${cart.total.toStringAsFixed(2)}'),
                    if (payment.method == 'CASH' && payment.change != null)
                      Text('Cambio: \$${payment.change!.toStringAsFixed(2)}'),
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
                    onSelectionChanged: (s) => setState(() => deliveryMode = s.first),
                  ),
                  const SizedBox(height: 12),

                  if (deliveryMode == 'PICKUP')
                    storesAsync.when(
                      data: (stores) {
                        if (stores.isEmpty) return const Text('No hay tiendas.');
                        selectedStoreId ??= stores.first.id;

                        return DropdownButtonFormField<String>(
                          value: selectedStoreId,
                          items: stores.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                          onChanged: (v) => setState(() => selectedStoreId = v),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Tienda',
                          ),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text('Error tiendas: $e'),
                    ),

                  if (deliveryMode == 'DELIVERY') ...[
                    TextField(
                      controller: addressCtrl,
                      minLines: 1,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Dirección (line1)',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Latitud (opcional)',
                      ),
                      onChanged: (v) => deliveryLat = double.tryParse(v),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Longitud (opcional)',
                      ),
                      onChanged: (v) => deliveryLong = double.tryParse(v),
                    ),
                    const SizedBox(height: 6),
                    const Text('Si no ingresas coordenadas, se usarán valores por defecto (demo).',
                        style: TextStyle(fontSize: 12)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          FilledButton(
            onPressed: loading ? null : _createOrder,
            child: loading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator())
                : const Text('Crear orden y ver tracking'),
          ),
        ],
      ),
    );
  }
}
