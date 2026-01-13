import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/remote/stores_remote_ds.dart';
import '../../data/repositories/stores_repository_impl.dart';
import '../../domain/entities/store.dart';
import '../../domain/repositories/stores_repository.dart';
import 'catalog_providers.dart'; // donde tienes apiClientProvider

final storesRemoteDsProvider = Provider<StoresRemoteDataSource>((ref) {
  final dio = ref.watch(apiClientProvider).dio;
  return StoresRemoteDataSource(dio);
});

final storesRepositoryProvider = Provider<StoresRepository>((ref) {
  return StoresRepositoryImpl(ref.watch(storesRemoteDsProvider));
});

final storesProvider = FutureProvider<List<Store>>((ref) async {
  return ref.watch(storesRepositoryProvider).getStores();
});
