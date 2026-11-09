import 'user_model.dart';

class PropertyModel {
  final int id;
  final int ownerId;
  final String title;
  final String type;
  final String description;
  final double priceMonthly;
  final int roomAvailable;
  final bool isAvailable;
  final String address;
  final String city;
  final double latitude;
  final double longitude;
  final List<String> facilities;
  final List<String> images;
  final double? distanceKm;
  final UserModel? owner;

  PropertyModel({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.type,
    required this.description,
    required this.priceMonthly,
    required this.roomAvailable,
    required this.isAvailable,
    required this.address,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.facilities,
    required this.images,
    this.distanceKm,
    this.owner,
  });

  String get typeLabel {
    switch (type) {
      case 'kost_putra':
        return 'Kos Putra';
      case 'kost_putri':
        return 'Kos Putri';
      case 'kost_campur':
        return 'Kos Campur';
      case 'kontrakan':
        return 'Kontrakan';
      default:
        return type;
    }
  }

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    return PropertyModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      ownerId: int.tryParse(json['owner_id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      type: json['type']?.toString() ?? 'kost_campur',
      description: json['description']?.toString() ?? '',
      priceMonthly:
          double.tryParse(json['price_monthly']?.toString() ?? '0') ?? 0.0,
      roomAvailable:
          int.tryParse(json['room_available']?.toString() ?? '0') ?? 0,
      isAvailable: json['is_available'] == true,
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
      facilities: (json['facilities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      distanceKm: json['distance_km'] != null
          ? double.tryParse(json['distance_km'].toString())
          : null,
      owner: json['owner'] is Map<String, dynamic>
          ? UserModel.fromJson(json['owner'] as Map<String, dynamic>)
          : null,
    );
  }
}
