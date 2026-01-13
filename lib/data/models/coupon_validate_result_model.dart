class CouponValidateResultModel {
  final bool valid;
  final double discountAmount;
  final double totalAfterDiscount;
  final String? code;

  const CouponValidateResultModel({
    required this.valid,
    required this.discountAmount,
    required this.totalAfterDiscount,
    this.code,
  });

  factory CouponValidateResultModel.fromJson(Map<String, dynamic> json) {
    return CouponValidateResultModel(
      valid: (json['valid'] ?? false) as bool,
      discountAmount: ((json['discountAmount'] ?? 0) as num).toDouble(),
      totalAfterDiscount: ((json['totalAfterDiscount'] ?? 0) as num).toDouble(),
      code: (json['coupon'] is Map)
          ? ((json['coupon']['code'] ?? '') as String)
          : null,
    );
  }
}
