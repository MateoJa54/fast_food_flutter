import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/cart_icon_button.dart';
import '../../providers/catalog_providers.dart';

class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCats = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              )
            : null,
        actions: [
          IconButton(
            tooltip: 'Locales',
            icon: const Icon(Icons.store),
            onPressed: () => context.push('/stores'),
          ),
          IconButton(
            tooltip: 'Refrescar',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(categoriesProvider),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
          CartIconButton(),
        ],
      ),
      body: asyncCats.when(
        data: (cats) {
          if (cats.isEmpty) {
            return const Center(
              child: Text('No hay categorías. Revisa datos del backend.'),
            );
          }

          return ListView.separated(
            itemCount: cats.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final c = cats[i];
              final icon = (c.icon == null || c.icon!.trim().isEmpty) ? '🍽️' : c.icon!;
              return ListTile(
                leading: Text(icon, style: const TextStyle(fontSize: 22)),
                title: Text(c.name),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // PUSH para mantener historial y permitir volver atrás
                  context.push('/products/${c.id}?name=${Uri.encodeComponent(c.name)}');
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) {
          debugPrint('ERROR categoriesProvider: $e');
          debugPrintStack(stackTrace: st);
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Error cargando categorías'),
                  const SizedBox(height: 8),
                  Text(e.toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => ref.invalidate(categoriesProvider),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
