class Store {
  final String id;
  final String name;
  final String address;
  final String openingHours;
  final double lat;
  final double long;
  final bool isActive;

  const Store({
    required this.id,
    required this.name,
    required this.address,
    required this.openingHours,
    required this.lat,
    required this.long,
    required this.isActive,
  });
}
