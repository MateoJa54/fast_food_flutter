import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaymentResult {
  final bool success;
  final String method;
  final String transactionId;
  final double amount;

  // 👇 SOLO aplica a CASH (puede ser null en CARD)
  final double? change;

  PaymentResult({
    required this.success,
    required this.method,
    required this.transactionId,
    required this.amount,
    this.change,
  });
}

class PaymentResultNotifier extends StateNotifier<PaymentResult?> {
  PaymentResultNotifier() : super(null);

  void setFromApi(Map<String, dynamic> res) {
    state = PaymentResult(
      success: (res['success'] ?? false) == true,
      method: (res['method'] ?? '').toString(),
      transactionId: (res['transactionId'] ?? '').toString(),
      amount: (res['amount'] is num) ? (res['amount'] as num).toDouble() : 0.0,
      // 👇 change viene solo en CASH (num o null)
      change: (res['change'] is num) ? (res['change'] as num).toDouble() : null,
    );
  }

  void clear() => state = null;
}

final paymentResultProvider =
    StateNotifierProvider<PaymentResultNotifier, PaymentResult?>((ref) {
  return PaymentResultNotifier();
});
