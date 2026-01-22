import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/cart_providers.dart';
import '../../providers/checkout_providers.dart';
import '../../providers/payment_providers.dart';
import 'input_formatters.dart';

class PaymentSimulatePage extends ConsumerStatefulWidget {
  const PaymentSimulatePage({super.key});

  @override
  ConsumerState<PaymentSimulatePage> createState() => _PaymentSimulatePageState();
}

class _PaymentSimulatePageState extends ConsumerState<PaymentSimulatePage> {
  String method = 'CARD'; // CARD / CASH
  bool loading = false;

  // Card controllers
  final panCtrl = TextEditingController();
  final holderCtrl = TextEditingController();
  final expiryCtrl = TextEditingController(); // MM/YY
  final cvvCtrl = TextEditingController();

  // Cash controller
  final cashGivenCtrl = TextEditingController();

  @override
  void dispose() {
    panCtrl.dispose();
    holderCtrl.dispose();
    expiryCtrl.dispose();
    cvvCtrl.dispose();
    cashGivenCtrl.dispose();
    super.dispose();
  }

  double _amount() => ref.read(cartProvider).total;

  String? _validateCard() {
    final panDigits = panCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (panDigits.length != 16) return 'La tarjeta debe tener 16 dígitos';

    final holder = holderCtrl.text.trim();
    if (holder.isEmpty) return 'Ingresa el nombre del titular';

    final exp = expiryCtrl.text.trim();
    final match = RegExp(r'^\d{2}/\d{2}$').hasMatch(exp);
    if (!match) return 'Fecha inválida (MM/YY)';

    final mm = int.tryParse(exp.substring(0, 2));
    final yy = int.tryParse(exp.substring(3, 5));
    if (mm == null || yy == null || mm < 1 || mm > 12) return 'Mes inválido';

    final cvv = cvvCtrl.text.trim();
    if (cvv.length < 3 || cvv.length > 4) return 'CVV debe tener 3 o 4 dígitos';

    return null;
  }

  String? _validateCash() {
    final given = double.tryParse(cashGivenCtrl.text.trim());
    if (given == null) return 'Ingresa el efectivo entregado';
    if (given < _amount()) return 'El efectivo debe ser >= al total';
    return null;
  }

  Future<void> _simulate() async {
    final cart = ref.read(cartProvider);
    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Carrito vacío')));
      return;
    }

    // Validaciones
    if (method == 'CARD') {
      final err = _validateCard();
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
        return;
      }
    } else {
      final err = _validateCash();
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
        return;
      }
    }

    setState(() => loading = true);

    try {
      final payments = ref.read(paymentsRemoteDsProvider);

      final payload = <String, dynamic>{
        'amount': cart.total,
        'currency': 'USD',
        'method': method,
      };

      if (method == 'CARD') {
        final panDigits = panCtrl.text.replaceAll(RegExp(r'\D'), '');
        final exp = expiryCtrl.text.trim(); // MM/YY
        final expMonth = int.parse(exp.substring(0, 2));
        final expYear = 2000 + int.parse(exp.substring(3, 5));

        payload['card'] = {
          'pan': panDigits,
          'holderName': holderCtrl.text.trim(),
          'expMonth': expMonth,
          'expYear': expYear,
          'cvv': cvvCtrl.text.trim(),
        };
      } else {
        payload['cash'] = {
          'given': double.parse(cashGivenCtrl.text.trim()),
        };
      }

      final res = await payments.simulatePayment(payload);

      // Guardar resultado en provider para CreateOrder / Checkout
      ref.read(paymentResultProvider.notifier).setFromApi(res);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message']?.toString() ?? 'Pago simulado')),
        );
        // opcional: navegar a crear orden
        context.push('/create-order');
      }
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
    final total = _amount();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pago'),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontWeight: FontWeight.w700)),
                  Text('\$${total.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Método
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Método de pago', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'CARD', label: Text('Tarjeta')),
                      ButtonSegment(value: 'CASH', label: Text('Efectivo')),
                    ],
                    selected: {method},
                    onSelectionChanged: (s) => setState(() => method = s.first),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          if (method == 'CARD') _cardForm(),
          if (method == 'CASH') _cashForm(total),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: loading ? null : _simulate,
              child: loading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator())
                  : const Text('Simular pago'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: panCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(16),
                CardNumberInputFormatter(),
              ],
              decoration: const InputDecoration(
                labelText: 'Número de tarjeta',
                hintText: '1234 5678 1234 5678',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.credit_card),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: holderCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Titular',
                hintText: 'Nombre Apellido',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: expiryCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [ExpiryInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Exp (MM/YY)',
                      hintText: '12/28',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: cvvCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'CVV',
                      hintText: '123',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Se acepta cualquier tarjeta válida de 16 dígitos (simulación).',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cashForm(double total) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: cashGivenCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Efectivo entregado',
                hintText: 'Ej: 10.00',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.payments),
                helperText: 'Debe ser mayor o igual al total (\$${total.toStringAsFixed(2)})',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
