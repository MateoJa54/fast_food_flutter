import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/stores_providers.dart';
import '../widgets/cart_icon_button.dart';
class StoresPage extends ConsumerWidget {
  const StoresPage({super.key});

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStores = ref.watch(storesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Locales'),
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              )
            : null,
        actions: [
          IconButton(
            tooltip: 'Refrescar',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(storesProvider),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
          CartIconButton(),
        ],
      ),
      body: asyncStores.when(
        data: (stores) {
          if (stores.isEmpty) return const Center(child: Text('No hay locales disponibles.'));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: stores.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final s = stores[i];
              return Card(
                child: ListTile(
                  title: Text(s.name),
                  subtitle: Text('${s.address}\nHorario: ${s.openingHours}'),
                  isThreeLine: true,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Seleccionaste: ${s.name}')),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error cargando locales:\n$e'),
          ),
        ),
      ),
    );
  }
}
