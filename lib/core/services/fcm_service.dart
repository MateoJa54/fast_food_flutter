import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../data/datasources/remote/notifications_remote_ds.dart';
import 'local_notifications_service.dart';

class FcmService {
  FcmService(this._notificationsDs);

  final NotificationsRemoteDataSource _notificationsDs;

  String _platform() {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    return 'android';
  }

  Future<void> init() async {
    final messaging = FirebaseMessaging.instance;

    // 1) Permisos (Android 13+ e iOS)
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    // 2) Token actual
    final token = await messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await _registerToken(token);
    } else {
      debugPrint('FCM token null/empty');
    }

    // 3) Refresh token
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      if (newToken.isNotEmpty) {
        await _registerToken(newToken);
      }
    });

    // 4) Foreground messages -> notificación local
    FirebaseMessaging.onMessage.listen((RemoteMessage msg) async {
      final title = msg.notification?.title ?? 'FastFood';
      final body = msg.notification?.body ?? 'Tienes una actualización';

      debugPrint('FCM onMessage -> $title | $body');

      await LocalNotificationsService.instance.show(title: title, body: body);
    });
  }

  Future<void> _registerToken(String token) async {
    try {
      await _notificationsDs.registerToken(
        token: token,
        platform: _platform(),
      );
      debugPrint('FCM token registrado OK');
    } catch (e) {
      debugPrint('Error registrando FCM token: $e');
    }
  }
}
