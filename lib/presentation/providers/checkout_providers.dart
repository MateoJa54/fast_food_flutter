import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/remote/orders_remote_ds.dart';
import '../../data/datasources/remote/payments_remote_ds.dart';
import 'catalog_providers.dart'; // apiClientProvider

final paymentsRemoteDsProvider = Provider<PaymentsRemoteDataSource>((ref) {
  final dio = ref.watch(apiClientProvider).dio;
  return PaymentsRemoteDataSource(dio);
});

final ordersRemoteDsProvider = Provider<OrdersRemoteDataSource>((ref) {
  final dio = ref.watch(apiClientProvider).dio;
  return OrdersRemoteDataSource(dio);
});
