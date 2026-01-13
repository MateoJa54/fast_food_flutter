import '../../domain/entities/product.dart';

String _cleanQuoted(String v) {
  // limpia strings tipo "\"Combo Big Burger\"" => Combo Big Burger
  return v.replaceAll('"', '').trim();
}

class ProductModel {
  final String id;
  final String name;
  final String description;
  final double basePrice;
  final String imageUrl;
  final bool isAvailable;
  final List<String> tags;
  final String? categoryId;

  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.basePrice,
    required this.imageUrl,
    required this.isAvailable,
    required this.tags,
    this.categoryId,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final rawImage = (json['imagenUrl'] ?? '') as String;
    // Manejo de clave mal escrita con espacio: "categoryId "
    final catId = (json['categoryId'] ?? json['categoryId '] ?? json['categoryId  ']) as String?;

    return ProductModel(
      id: (json['id'] ?? '') as String,
      name: _cleanQuoted((json['name'] ?? '') as String),
      description: _cleanQuoted((json['description'] ?? '') as String),
      basePrice: ((json['basePrice'] ?? 0) as num).toDouble(),
      imageUrl: _cleanQuoted(rawImage),
      isAvailable: (json['isAvailable'] ?? true) as bool,
      tags: (json['tags'] as List? ?? []).map((e) => e.toString()).toList(),
      categoryId: catId,
    );
  }

  Product toEntity() => Product(
        id: id,
        name: name,
        description: description,
        basePrice: basePrice,
        imageUrl: imageUrl,
        isAvailable: isAvailable,
        tags: tags,
        categoryId: categoryId,
      );
}
