import 'package:dio/dio.dart';

class OrdersRemoteDataSource {
  OrdersRemoteDataSource(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> payload) async {
    final res = await _dio.post('/orders', data: payload);
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> getOrderById(String orderId) async {
    final res = await _dio.get('/orders/$orderId');
    return Map<String, dynamic>.from(res.data as Map);
  }
  Future<List<dynamic>> getMyOrders() async {
  final res = await _dio.get('/orders/my');
  if (res.data is List) return res.data as List;
  return [];
}
}
