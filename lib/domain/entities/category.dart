class Category {
  final String id;
  final String name;
  final int sortOrder;
  final String? icon;

  const Category({
    required this.id,
    required this.name,
    required this.sortOrder,
    this.icon,
  });
}
