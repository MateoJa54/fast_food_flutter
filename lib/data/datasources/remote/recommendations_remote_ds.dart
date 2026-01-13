import 'package:dio/dio.dart';

class RecommendationsRemoteDataSource {
  RecommendationsRemoteDataSource(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> getMyRecommendations({int limit = 5}) async {
    final res = await _dio.get('/recommendations/my', queryParameters: {'limit': limit});
    return Map<String, dynamic>.from(res.data as Map);
  }
}
