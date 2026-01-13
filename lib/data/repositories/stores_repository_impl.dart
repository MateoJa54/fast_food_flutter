import '../../domain/entities/store.dart';
import '../../domain/repositories/stores_repository.dart';
import '../datasources/remote/stores_remote_ds.dart';

class StoresRepositoryImpl implements StoresRepository {
  StoresRepositoryImpl(this._remote);
  final StoresRemoteDataSource _remote;

  @override
  Future<List<Store>> getStores() async {
    final models = await _remote.getStores();
    return models.map((m) => m.toEntity()).where((s) => s.isActive).toList();
  }
}
