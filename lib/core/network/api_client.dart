import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/env.dart';
import 'auth_interceptor.dart';

class ApiClient {
  ApiClient(this._auth) {
    dio = Dio(
      BaseOptions(
        baseUrl: Env.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(AuthInterceptor(_auth));
  }

  final FirebaseAuth _auth;
  late final Dio dio;
}
