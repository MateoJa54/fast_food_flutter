class Product {
  final String id;
  final String name;
  final String description;
  final double basePrice;
  final String imageUrl;
  final bool isAvailable;
  final List<String> tags;
  final String? categoryId;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.basePrice,
    required this.imageUrl,
    required this.isAvailable,
    required this.tags,
    this.categoryId,
  });
}
