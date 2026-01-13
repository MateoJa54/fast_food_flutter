import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../datasources/remote/catalog_remote_ds.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  CatalogRepositoryImpl(this._remote);
  final CatalogRemoteDataSource _remote;

  @override
  Future<List<Category>> getCategories() async {
    final models = await _remote.getCategories(); // List<CategoryModel>
    final cats = models.map((m) => m.toEntity()).toList();

    cats.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return cats.where((c) => c.name.isNotEmpty).toList();
  }

  @override
  Future<List<Product>> getProducts({String? categoryId}) async {
    final models = await _remote.getProducts(categoryId: categoryId); // List<ProductModel>
    return models.map((m) => m.toEntity()).where((p) => p.isAvailable).toList();
  }

  @override
  Future<Product> getProductById(String id) async {
    final model = await _remote.getProductById(id);
    return model.toEntity();
  }
}
