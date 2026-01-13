import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'checkout_providers.dart'; // ordersRemoteDsProvider

final orderLiveProvider = StreamProvider.autoDispose.family<Map<String, dynamic>, String>((ref, orderId) async* {
  final ds = ref.read(ordersRemoteDsProvider);

  while (true) {
    final data = await ds.getOrderById(orderId); // <-- crea este método si no lo tienes
    yield Map<String, dynamic>.from(data);

    final status = (data['status'] ?? '').toString();
    if (status == 'DELIVERED' || status == 'CANCELLED') {
      break; // ya terminó el pedido, paramos polling
    }

    // Polling interval (recomendado 3–5s)
    await Future<void>.delayed(const Duration(seconds: 4));
  }
});
