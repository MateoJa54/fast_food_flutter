import 'package:dio/dio.dart';
import '../../models/category_model.dart';
import '../../models/product_model.dart';

class CatalogRemoteDataSource {
  CatalogRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<CategoryModel>> getCategories() async {
    final res = await _dio.get('/catalog/categories');

    final data = res.data;
    if (data is! List) {
      throw DioException(
        requestOptions: res.requestOptions,
        message: 'Formato inesperado en /catalog/categories',
        type: DioExceptionType.badResponse,
      );
    }

    return data
        .map((e) => CategoryModel.fromJson(Map<String, dynamic>.from(e)))
        .toList()
        .cast<CategoryModel>();
  }

  Future<List<ProductModel>> getProducts({String? categoryId}) async {
    final res = await _dio.get(
      '/catalog/products',
      queryParameters: categoryId == null ? null : {'categoryId': categoryId},
    );

    final data = res.data;
    if (data is! List) {
      throw DioException(
        requestOptions: res.requestOptions,
        message: 'Formato inesperado en /catalog/products',
        type: DioExceptionType.badResponse,
      );
    }

    return data
        .map((e) => ProductModel.fromJson(Map<String, dynamic>.from(e)))
        .toList()
        .cast<ProductModel>();
  }

  Future<ProductModel> getProductById(String id) async {
    final res = await _dio.get('/catalog/products/$id');
    return ProductModel.fromJson(Map<String, dynamic>.from(res.data));
  }
}
