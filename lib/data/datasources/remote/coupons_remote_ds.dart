import 'package:dio/dio.dart';
import '../../models/coupon_validate_result_model.dart';

class CouponsRemoteDataSource {
  CouponsRemoteDataSource(this._dio);
  final Dio _dio;

  Future<CouponValidateResultModel> validateCoupon({
    required String code,
    required double subtotal,
  }) async {
    final res = await _dio.post('/coupons/validate', data: {
      'code': code,
      'subtotal': subtotal,
    });

    return CouponValidateResultModel.fromJson(
      Map<String, dynamic>.from(res.data as Map),
    );
  }
}
