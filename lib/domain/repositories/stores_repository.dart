import '../entities/store.dart';

abstract class StoresRepository {
  Future<List<Store>> getStores();
}
