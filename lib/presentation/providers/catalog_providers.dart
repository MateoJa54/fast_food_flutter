import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../data/datasources/remote/catalog_remote_ds.dart';
import '../../data/repositories/catalog_repository_impl.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(FirebaseAuth.instance);
});

final catalogRemoteDsProvider = Provider<CatalogRemoteDataSource>((ref) {
  return CatalogRemoteDataSource(ref.watch(apiClientProvider).dio);
});

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepositoryImpl(ref.watch(catalogRemoteDsProvider));
});

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  return ref.watch(catalogRepositoryProvider).getCategories();
});

final productsProvider =
    FutureProvider.family<List<Product>, String?>((ref, categoryId) async {
  return ref.watch(catalogRepositoryProvider).getProducts(categoryId: categoryId);
});

final productDetailProvider =
    FutureProvider.family<Product, String>((ref, id) async {
  return ref.watch(catalogRepositoryProvider).getProductById(id);
});
