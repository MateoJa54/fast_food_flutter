import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/fcm_service.dart';
import 'remote_ds_providers.dart'; 
final fcmServiceProvider = Provider<FcmService>((ref) {
  final ds = ref.read(notificationsRemoteDsProvider);
  return FcmService(ds);
});
