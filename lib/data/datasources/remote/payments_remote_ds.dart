import 'package:dio/dio.dart';

class PaymentsRemoteDataSource {
  PaymentsRemoteDataSource(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> simulatePayment(Map<String, dynamic> payload) async {
    final res = await _dio.post('/payments/simulate', data: payload);
    return Map<String, dynamic>.from(res.data as Map);
  }
}
