import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'checkout_providers.dart';

final myOrdersProvider = FutureProvider<List<dynamic>>((ref) async {
  final ds = ref.watch(ordersRemoteDsProvider);

  try {
    return await ds.getMyOrders();
  } on DioException catch (e) {
    // Si tu backend usa 404 para "no hay pedidos", lo convertimos a lista vacía
    if (e.response?.statusCode == 404) return [];
    rethrow;
  }
});
