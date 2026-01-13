import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/cart_providers.dart';
import '../../providers/checkout_providers.dart';
import '../../providers/payment_providers.dart';

class PaymentSimulatePage extends ConsumerStatefulWidget {
  const PaymentSimulatePage({super.key});

  @override
  ConsumerState<PaymentSimulatePage> createState() => _PaymentSimulatePageState();
}

class _PaymentSimulatePageState extends ConsumerState<PaymentSimulatePage> {
  bool loading = false;
  String method = 'CARD';

  Future<void> _simulate() async {
    final cart = ref.read(cartProvider);
    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tu carrito está vacío')),
      );
      return;
    }

    setState(() => loading = true);
    try {
      final ds = ref.read(paymentsRemoteDsProvider);
      final res = await ds.simulatePayment(
        amount: cart.total,
        currency: 'USD',
        paymentMethod: method,
      );

      final success = (res['success'] ?? false) as bool;
      final tx = (res['transactionId'] ?? '').toString();
      final msg = (res['message'] ?? 'Pago simulado').toString();

      ref.read(paymentResultProvider.notifier).state = PaymentState(
        success: success,
        transactionId: tx,
        message: msg,
        method: method,
        amount: cart.total,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Pago aprobado' : 'Pago rechazado')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error simulando pago: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final pay = ref.watch(paymentResultProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pago (Simulación)'),
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
                  _row('Total a pagar', '\$${cart.total.toStringAsFixed(2)}', bold: true),
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
                  const Text('Método', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: method,
                    items: const [
                      DropdownMenuItem(value: 'CARD', child: Text('Tarjeta (simulada)')),
                      DropdownMenuItem(value: 'CASH', child: Text('Efectivo (simulado)')),
                    ],
                    onChanged: (v) => setState(() => method = v ?? 'CARD'),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Método de pago',
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: loading ? null : _simulate,
                    child: loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator())
                        : const Text('Simular pago'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (pay != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Resultado', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    _row('Estado', pay.success ? 'APPROVED' : 'REJECTED'),
                    _row('TransactionId', pay.transactionId.isEmpty ? '(sin id)' : pay.transactionId),
                    _row('Mensaje', pay.message),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: pay.success ? () => context.push('/create-order') : null,
                      child: const Text('Continuar: Crear orden'),
                    ),
                  ],
                ),
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
          Flexible(child: Text(value, style: style, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}
