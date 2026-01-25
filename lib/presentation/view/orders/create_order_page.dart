import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/cart_providers.dart';
import '../../providers/checkout_providers.dart'; // ordersRemoteDsProvider
import '../../providers/payment_providers.dart';  // paymentResultProvider
import '../../providers/stores_providers.dart';

class CreateOrderPage extends ConsumerStatefulWidget {
  const CreateOrderPage({super.key});

  @override
  ConsumerState<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends ConsumerState<CreateOrderPage> {
  String deliveryMode = 'PICKUP'; // PICKUP / DELIVERY
  String? selectedStoreId;

  // DELIVERY fields (según tu backend)
  final streetCtrl = TextEditingController();
  final referenceCtrl = TextEditingController();

  double? deliveryLat;
  double? deliveryLng;

  bool showAdvancedCoords = false;
  bool loading = false;

  @override
  void dispose() {
    streetCtrl.dispose();
    referenceCtrl.dispose();
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Carrito vacío')),
      );
      return;
    }

    if (payment == null || !payment.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero realiza un pago aprobado')),
      );
      return;
    }

    // ✅ storeId requerido en PICKUP y DELIVERY (según tu curl)
    if (selectedStoreId == null || selectedStoreId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una tienda')),
      );
      return;
    }

    if (deliveryMode == 'DELIVERY') {
      if (streetCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingresa la calle (street)')),
        );
        return;
      }
      if (referenceCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingresa una referencia')),
        );
        return;
      }

      // coords opcionales: defaults válidos si no se ingresa
      deliveryLat ??= -0.3345;
      deliveryLng ??= -78.4421;
    }

    setState(() => loading = true);

    try {
      final orders = ref.read(ordersRemoteDsProvider);

      // ✅ Payload EXACTO a tu backend (/orders)
      final payload = <String, dynamic>{
        'clientOrderId': _clientOrderId(),
        'items': cart.items
            .map((i) => {
                  'productId': i.productId,
                  'qty': i.qty,
                  'nameSnapshot': i.nameSnapshot,
                  'priceSnapshot': i.priceSnapshot,
                  'tagsSnapshot': i.tagsSnapshot,
                  if (i.notes != null && i.notes!.trim().isNotEmpty) 'notes': i.notes!.trim(),
                  if (i.modifiersSnapshot.isNotEmpty) 'modifiersSnapshot': i.modifiersSnapshot,
                })
            .toList(),
        'deliveryMode': deliveryMode,
        'storeId': selectedStoreId, // ✅ siempre string
        'totals': {
          'subtotal': cart.subtotal,
          'discountTotal': cart.discountAmount,
          'total': cart.total,
        },
        'paymentTransactionId': payment.transactionId, // ✅ clave
      };

      // addressSnapshot: null en PICKUP, objeto en DELIVERY
      if (deliveryMode == 'PICKUP') {
        payload['addressSnapshot'] = null;
      } else {
        payload['addressSnapshot'] = {
          'street': streetCtrl.text.trim(),
          'reference': referenceCtrl.text.trim(),
          'lat': deliveryLat,
          'lng': deliveryLng, // ✅ OJO: tu backend usa "lng" no "long"
        };
      }

      // couponSnapshot solo si existe
      if (cart.couponCode != null && cart.couponCode!.trim().isNotEmpty) {
        payload['couponSnapshot'] = {
          'code': cart.couponCode,
          'discountAmount': cart.discountAmount,
        };
      }

      debugPrint('ORDER_PAYLOAD: $payload');

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
        debugPrint('HEADERS: ${e.response?.headers}');
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
                    const Text('Pago aprobado', style: TextStyle(fontWeight: FontWeight.w600)),
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
                    onSelectionChanged: (s) {
                      setState(() {
                        deliveryMode = s.first;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // ✅ Tienda siempre (PICKUP y DELIVERY) por cómo es tu backend
                  storesAsync.when(
                    data: (stores) {
                      if (stores.isEmpty) return const Text('No hay tiendas.');
                      selectedStoreId ??= stores.first.id;

                      return DropdownButtonFormField<String>(
                        value: selectedStoreId,
                        items: stores
                            .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                            .toList(),
                        onChanged: (v) => setState(() => selectedStoreId = v),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Tienda (storeId)',
                        ),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error tiendas: $e'),
                  ),

                  if (deliveryMode == 'DELIVERY') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: streetCtrl,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Calle / Street',
                        hintText: 'Ej: Av. General Rumiñahui',
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: referenceCtrl,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Referencia',
                        hintText: 'Ej: Frente al parque',
                      ),
                      minLines: 1,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 10),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Coordenadas (opcional)'),
                      subtitle: const Text('Si no las ingresas, se usan valores demo.'),
                      value: showAdvancedCoords,
                      onChanged: (v) => setState(() => showAdvancedCoords = v),
                    ),

                    if (showAdvancedCoords) ...[
                      TextField(
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Latitud (lat)',
                        ),
                        onChanged: (v) => deliveryLat = double.tryParse(v),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Longitud (lng)',
                        ),
                        onChanged: (v) => deliveryLng = double.tryParse(v),
                      ),
                    ],
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
