import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../data/datasources/remote/notifications_remote_ds.dart';
import 'catalog_providers.dart'; // apiClientProvider

// Provider del RemoteDataSource
final notificationsRemoteDsProvider = Provider<NotificationsRemoteDataSource>((ref) {
  final dio = ref.watch(apiClientProvider).dio;
  return NotificationsRemoteDataSource(dio);
});

// Servicio FCM (1 solo)
final fcmServiceProvider = Provider<FcmService>((ref) {
  final ds = ref.read(notificationsRemoteDsProvider);
  return FcmService(ds);
});

class FcmService {
  final NotificationsRemoteDataSource _ds;
  FcmService(this._ds);

  Future<void> initAndRegisterToken() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // Permisos (Android 13+/iOS). Seguro llamarlo siempre.
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      final token = await messaging.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('FCM token null/empty');
        return;
      }

      await _ds.registerToken(token: token, platform: 'android');

      // Refresh token
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        if (newToken.isNotEmpty) {
          await _ds.registerToken(token: newToken, platform: 'android');
        }
      });

      debugPrint('FCM token registrado OK');
    } catch (e) {
      debugPrint('Error registrando FCM token: $e');
    }
  }
}
