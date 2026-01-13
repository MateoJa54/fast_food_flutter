import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/remote/coupons_remote_ds.dart';
import '../../data/models/coupon_validate_result_model.dart';
import 'catalog_providers.dart'; // apiClientProvider
import 'cart_providers.dart';

final couponsRemoteDsProvider = Provider<CouponsRemoteDataSource>((ref) {
  final dio = ref.watch(apiClientProvider).dio;
  return CouponsRemoteDataSource(dio);
});

final validateCouponProvider = FutureProvider.family<CouponValidateResultModel, String>((ref, code) async {
  final cart = ref.watch(cartProvider);
  final ds = ref.watch(couponsRemoteDsProvider);

  return ds.validateCoupon(
    code: code.trim(),
    subtotal: cart.subtotal,
  );
});
