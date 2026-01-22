import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/cart_providers.dart';
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

  // Demo coords (si no usas mapas todavía)
  double? deliveryLat;
  double? deliveryLong;

  @override
  void dispose() {
    addressCtrl.dispose();
    super.dispose();
  }

  void _continueToPayment() {
    final cart = ref.read(cartProvider);

    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tu carrito está vacío')),
      );
      return;
    }

    if (deliveryMode == 'PICKUP') {
      if (selectedStoreId == null || selectedStoreId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona una tienda para Pickup')),
        );
        return;
      }
    }

    if (deliveryMode == 'DELIVERY') {
      if (addressCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingresa una dirección para Delivery')),
        );
        return;
      }
      // Si no pones coords, usa demo (ESPE)
      deliveryLat ??= -0.3345;
      deliveryLong ??= -78.4421;
    }

    // Guardamos preferencia de entrega dentro del carrito (o en un provider aparte).
    // Aquí lo más simple: lo mandamos por query params hacia /pay.
    final qp = <String, String>{
      'mode': deliveryMode,
      if (deliveryMode == 'PICKUP') 'storeId': selectedStoreId!,
      if (deliveryMode == 'DELIVERY') 'line1': addressCtrl.text.trim(),
      if (deliveryMode == 'DELIVERY') 'lat': (deliveryLat ?? -0.3345).toString(),
      if (deliveryMode == 'DELIVERY') 'long': (deliveryLong ?? -78.4421).toString(),
    };

    context.push(Uri(path: '/pay', queryParameters: qp).toString());
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
          // Resumen
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

          // Entrega
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
                        labelText: 'Dirección (line1)',
                        border: OutlineInputBorder(),
                      ),
                      minLines: 1,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Latitud (opcional)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) => deliveryLat = double.tryParse(v),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Longitud (opcional)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) => deliveryLong = double.tryParse(v),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Si no ingresas coordenadas, se usarán valores por defecto (demo).',
                      style: TextStyle(fontSize: 12),
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
              onPressed: _continueToPayment,
              child: const Text('Continuar a pago'),
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
