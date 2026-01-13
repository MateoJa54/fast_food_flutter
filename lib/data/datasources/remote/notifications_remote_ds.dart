import 'package:dio/dio.dart';

class NotificationsRemoteDataSource {
  NotificationsRemoteDataSource(this._dio);
  final Dio _dio;

  Future<void> registerToken({
    required String token,
    required String platform,
  }) async {
    await _dio.post(
      '/notifications/register-token',
      data: {
        'token': token,
        'platform': platform,
      },
    );
  }
}
