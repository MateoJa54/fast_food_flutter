import 'package:dio/dio.dart';
import '../../models/store_model.dart';

class StoresRemoteDataSource {
  StoresRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<StoreModel>> getStores() async {
    final res = await _dio.get('/stores');
    final data = res.data;

    if (data is! List) {
      throw DioException(
        requestOptions: res.requestOptions,
        message: 'Formato inesperado en /stores',
        type: DioExceptionType.badResponse,
      );
    }

    return data
        .map((e) => StoreModel.fromJson(Map<String, dynamic>.from(e)))
        .toList()
        .cast<StoreModel>();
  }
}
