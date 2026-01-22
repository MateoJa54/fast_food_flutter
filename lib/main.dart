import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/services/local_notifications_service.dart';
import 'presentation/providers/fcm_providers.dart';
import 'presentation/providers/router_provider.dart'; // tu router actual

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Inicializa canales de notificación (Android 8+)
  await LocalNotificationsService.instance.init();

  runApp(const ProviderScope(child: AppBootstrap()));
}

class AppBootstrap extends ConsumerStatefulWidget {
  const AppBootstrap({super.key});

  @override
  ConsumerState<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends ConsumerState<AppBootstrap> {
  bool _inited = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_inited) return;
    _inited = true;

    // Inicializa FCM solo 1 vez
    Future.microtask(() async {
      await ref.read(fcmServiceProvider).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
