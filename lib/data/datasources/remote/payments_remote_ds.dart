import 'package:dio/dio.dart';

class PaymentsRemoteDataSource {
  PaymentsRemoteDataSource(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> simulatePayment({
    required double amount,
    String currency = 'USD',
    String paymentMethod = 'CARD',
  }) async {
    final res = await _dio.post('/payments/simulate', data: {
      'amount': amount,
      'currency': currency,
      'paymentMethod': paymentMethod,
    });

    return Map<String, dynamic>.from(res.data as Map);
  }
}
