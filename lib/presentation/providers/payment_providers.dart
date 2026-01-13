import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaymentState {
  final bool success;
  final String transactionId;
  final String message;
  final String method;
  final double amount;

  const PaymentState({
    required this.success,
    required this.transactionId,
    required this.message,
    required this.method,
    required this.amount,
  });
}

/// Guarda el último resultado de pago simulado (o null si no hay)
final paymentResultProvider = StateProvider<PaymentState?>((ref) => null);
