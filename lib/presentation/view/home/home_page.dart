import 'dart:ui';

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
  Future<void> _signOut() async => FirebaseAuth.instance.signOut();

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      await ref.read(fcmRegisterServiceProvider).registerCurrentDeviceToken();
    });

    FirebaseMessaging.onMessage.listen((message) {
      if (!mounted) return;
      final title = message.notification?.title ?? 'Notificación';
      final body = message.notification?.body ?? '';

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(12),
            content: Text(body.isEmpty ? title : '$title · $body'),
            action: SnackBarAction(
              label: 'Ver',
              onPressed: () => context.push('/orders'),
            ),
          ),
        );
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final scheme = Theme.of(context).colorScheme;

    final displayName = (user?.displayName?.trim().isNotEmpty ?? false) ? user!.displayName!.trim() : null;
    final email = (user?.email?.trim().isNotEmpty ?? false) ? user!.email!.trim() : null;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('FastFood'),
            floating: false,
            pinned: true,
            stretch: true,
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

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  // Header premium
                  _ProfileHeader(
                    name: displayName ?? 'Bienvenido',
                    subtitle: email ?? 'Listo para tu próximo pedido',
                    onOrdersTap: () => context.push('/orders'),
                  ),

                  const SizedBox(height: 16),

                  // Recomendaciones
                  const RecommendationsSection(limit: 5),

                  const SizedBox(height: 18),

                  // Quick actions tipo iOS
                  Text(
                    'Accesos rápidos',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _ActionPill(
                        icon: Icons.fastfood,
                        label: 'Ordenar ahora',
                        tone: _PillTone.primary,
                        onTap: () => context.push('/categories'),
                      ),
                      _ActionPill(
                        icon: Icons.store,
                        label: 'Locales',
                        tone: _PillTone.neutral,
                        onTap: () => context.push('/stores'),
                      ),
                      _ActionPill(
                        icon: Icons.receipt_long,
                        label: 'Mis pedidos',
                        tone: _PillTone.neutral,
                        onTap: () => context.push('/orders'),
                      ),
                      _ActionPill(
                        icon: Icons.shopping_cart,
                        label: 'Carrito',
                        tone: _PillTone.neutral,
                        onTap: () => context.push('/cart'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Card “call to action” grande (más visual que ListTile)
                  _BigCtaCard(
                    title: 'Arma tu combo 🍗',
                    subtitle: 'Explora el menú y personaliza tu pedido.',
                    buttonText: 'Explorar categorías',
                    onTap: () => context.push('/categories'),
                    background: scheme.surfaceContainerHighest,
                  ),

                  const SizedBox(height: 26),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.subtitle,
    required this.onOrdersTap,
  });

  final String name;
  final String subtitle;
  final VoidCallback onOrdersTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withOpacity(0.75),
            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
                child: const Icon(Icons.person),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: onOrdersTap,
                icon: const Icon(Icons.receipt_long),
                label: const Text('Pedidos'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _PillTone { primary, neutral }

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
    this.tone = _PillTone.neutral,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final _PillTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final bg = tone == _PillTone.primary ? scheme.primaryContainer : scheme.surfaceContainerHighest;
    final fg = tone == _PillTone.primary ? scheme.onPrimaryContainer : scheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800, color: fg),
            ),
          ],
        ),
      ),
    );
  }
}

class _BigCtaCard extends StatelessWidget {
  const _BigCtaCard({
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onTap,
    required this.background,
  });

  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onTap;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: onTap,
                    child: Text(buttonText),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.chevron_right, size: 26),
          ],
        ),
      ),
    );
  }
}
