import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/notifications_providers.dart';

final fcmRegisterServiceProvider = Provider<FCMRegisterService>((ref) {
  return FCMRegisterService(ref);
});

class FCMRegisterService {
  FCMRegisterService(this.ref);
  final Ref ref;

  Future<void> registerCurrentDeviceToken() async {
    try {
      final messaging = FirebaseMessaging.instance;

      await messaging.requestPermission(alert: true, badge: true, sound: true);

      final token = await messaging.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('FCM token null/empty');
        return;
      }

      final ds = ref.read(notificationsRemoteDsProvider);

      // FIX: sin platformProvider
      await ds.registerToken(token: token, platform: 'android');

      // Token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        if (newToken.isNotEmpty) {
          await ds.registerToken(token: newToken, platform: 'android');
        }
      });

      debugPrint('FCM token registrado OK');
    } catch (e) {
      debugPrint('Error registrando FCM token: $e');
    }
  }
}
