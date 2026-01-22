class PaymentResult {
  final bool success;
  final String status; // SIMULATED_APPROVED / SIMULATED_DECLINED
  final String method; // CARD / CASH
  final String transactionId;
  final DateTime paidAt;

  // card-like
  final String? brand;
  final String? last4;
  final String? authCode;

  // cash-like
  final double? cashGiven;
  final double? change;

  final String message;

  const PaymentResult({
    required this.success,
    required this.status,
    required this.method,
    required this.transactionId,
    required this.paidAt,
    required this.message,
    this.brand,
    this.last4,
    this.authCode,
    this.cashGiven,
    this.change,
  });
}
