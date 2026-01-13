import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/remote/recommendations_remote_ds.dart';
import 'catalog_providers.dart'; // apiClientProvider

final recommendationsRemoteDsProvider = Provider<RecommendationsRemoteDataSource>((ref) {
  final dio = ref.watch(apiClientProvider).dio;
  return RecommendationsRemoteDataSource(dio);
});

final recommendationsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, int>((ref, limit) async {
  final ds = ref.read(recommendationsRemoteDsProvider);
  return ds.getMyRecommendations(limit: limit);
});
