import '../../domain/entities/category.dart';

class CategoryModel {
  final String id;
  final String name;
  final bool isActive;
  final int sortOrder;
  final String? icon;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.isActive,
    required this.sortOrder,
    this.icon,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: (json['id'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      isActive: (json['isActive'] ?? true) as bool,
      sortOrder: (json['sortOrder'] ?? 0) as int,
      icon: json['icon'] as String?,
    );
  }

  Category toEntity() => Category(
        id: id,
        name: name,
        sortOrder: sortOrder,
        icon: icon,
      );
}
