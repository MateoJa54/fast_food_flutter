import '../../domain/entities/store.dart';

class StoreModel {
  final String id;
  final String name;
  final String address;
  final String openingHours;
  final double lat;
  final double long;
  final bool isActive;

  const StoreModel({
    required this.id,
    required this.name,
    required this.address,
    required this.openingHours,
    required this.lat,
    required this.long,
    required this.isActive,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: (json['id'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      address: (json['address'] ?? '') as String,
      openingHours: (json['openingHours'] ?? '') as String,
      lat: ((json['lat'] ?? 0) as num).toDouble(),
      long: ((json['long'] ?? 0) as num).toDouble(),
      isActive: (json['isActive'] ?? true) as bool,
    );
  }

  Store toEntity() => Store(
        id: id,
        name: name,
        address: address,
        openingHours: openingHours,
        lat: lat,
        long: long,
        isActive: isActive,
      );
}
