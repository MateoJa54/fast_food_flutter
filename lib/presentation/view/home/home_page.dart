import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/cart_icon_button.dart';
import '../widgets/recommendations_section.dart';
import '../../services/fcm_register_service.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  void initState() {
    super.initState();

    // 1) Registrar token FCM una sola vez al entrar (post-login)
    Future.microtask(() async {
      await ref.read(fcmRegisterServiceProvider).registerCurrentDeviceToken();
    });

    // 2) Foreground: si llega notificación con la app abierta, mostramos SnackBar
    FirebaseMessaging.onMessage.listen((message) {
      final title = message.notification?.title ?? 'Notificación';
      final body = message.notification?.body ?? '';
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$title: $body')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FastFood'),
        actions: [
          IconButton(
            tooltip: 'Mis pedidos',
            icon: const Icon(Icons.receipt_long),
            onPressed: () => context.push('/orders'),
          ),
          const CartIconButton(),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const CircleAvatar(radius: 22, child: Icon(Icons.person)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bienvenido',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user != null ? 'UID: ${user.uid}' : 'Sin sesión',
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Mis pedidos',
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () => context.push('/orders'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Recomendaciones IA (sección “Para ti”)
          const RecommendationsSection(limit: 5),

          const SizedBox(height: 18),

          // Accesos rápidos
          const Text(
            'Accesos rápidos',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),

          _QuickCard(
            title: 'Ordenar ahora',
            subtitle: 'Explora categorías y arma tu combo',
            icon: Icons.fastfood,
            onTap: () => context.push('/categories'),
            primary: true,
          ),
          const SizedBox(height: 10),

          _QuickCard(
            title: 'Locales',
            subtitle: 'Ver tiendas disponibles y ubicación',
            icon: Icons.store,
            onTap: () => context.push('/stores'),
          ),
          const SizedBox(height: 10),

          _QuickCard(
            title: 'Mis pedidos',
            subtitle: 'Historial y tracking de órdenes',
            icon: Icons.receipt_long,
            onTap: () => context.push('/orders'),
          ),
          const SizedBox(height: 10),

          _QuickCard(
            title: 'Carrito',
            subtitle: 'Revisa tu pedido antes de pagar',
            icon: Icons.shopping_cart,
            onTap: () => context.push('/cart'),
          ),
        ],
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.primary = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: primary ? 2 : 1,
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
