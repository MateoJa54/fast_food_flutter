import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._auth);
  final FirebaseAuth _auth;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final user = _auth.currentUser;
    if (user != null) {
      final token = await user.getIdToken();
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
