import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../models/property_model.dart';

class PropertyService {
  final ApiClient _apiClient = ApiClient();

  Future<List<PropertyModel>> getProperties({
    String? search,
    String? type,
    double? minPrice,
    double? maxPrice,
    String? city,
    int page = 1,
    int limit = 20,
  }) async {
    final Map<String, dynamic> query = {
      'page': page,
      'limit': limit,
    };
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (type != null && type.isNotEmpty && type != 'all') query['type'] = type;
    if (minPrice != null && minPrice > 0) query['min_price'] = minPrice;
    if (maxPrice != null && maxPrice > 0) query['max_price'] = maxPrice;
    if (city != null && city.isNotEmpty) query['city'] = city;

    final response = await _apiClient.dio.get(
      ApiEndpoints.properties,
      queryParameters: query,
    );

    final List<dynamic> rawList = response.data['data'] ?? [];
    return rawList
        .map((e) => PropertyModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PropertyModel>> getNearbyProperties({
    required double lat,
    required double lng,
    double radius = 5.0,
    String type = 'all',
  }) async {
    final response = await _apiClient.dio.get(
      ApiEndpoints.nearbyProperties,
      queryParameters: {
        'lat': lat,
        'lng': lng,
        'radius': radius,
        'type': type,
      },
    );

    final List<dynamic> rawList = response.data['data'] ?? [];
    return rawList
        .map((e) => PropertyModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PropertyModel> getPropertyDetail(int id) async {
    final response = await _apiClient.dio.get(ApiEndpoints.propertyDetail(id));
    return PropertyModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<bool> toggleWishlist(int propertyId) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.toggleWishlist(propertyId),
    );
    return response.data['data']?['wishlisted'] == true;
  }

  Future<List<PropertyModel>> getWishlists() async {
    final response = await _apiClient.dio.get(ApiEndpoints.wishlists);
    final List<dynamic> rawList = response.data['data'] ?? [];
    return rawList
        .where((item) => item['property'] != null)
        .map(
          (item) => PropertyModel.fromJson(
            item['property'] as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  // Owner Endpoints
  Future<List<PropertyModel>> getOwnerProperties() async {
    final response = await _apiClient.dio.get(ApiEndpoints.ownerProperties);
    final List<dynamic> rawList = response.data['data'] ?? [];
    return rawList
        .map((e) => PropertyModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PropertyModel> createProperty({
    required String title,
    required String type,
    required String description,
    required double priceMonthly,
    required int roomAvailable,
    required String address,
    required String city,
    required double latitude,
    required double longitude,
    required List<String> facilities,
    required List<File> imageFiles,
  }) async {
    final formData = FormData.fromMap({
      'title': title,
      'type': type,
      'description': description,
      'price_monthly': priceMonthly,
      'room_available': roomAvailable,
      'address': address,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'facilities': jsonEncode(facilities),
    });

    for (final file in imageFiles) {
      formData.files.add(
        MapEntry(
          'images',
          await MultipartFile.fromFile(
            file.path,
            filename: file.path.split('/').last,
          ),
        ),
      );
    }

    final response = await _apiClient.dio.post(
      ApiEndpoints.ownerProperties,
      data: formData,
    );
    return PropertyModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<PropertyModel> updateProperty({
    required int id,
    required String title,
    required String type,
    required String description,
    required double priceMonthly,
    required int roomAvailable,
    required String address,
    required String city,
    required double latitude,
    required double longitude,
    required List<String> facilities,
    List<File> newImageFiles = const [],
  }) async {
    final formData = FormData.fromMap({
      'title': title,
      'type': type,
      'description': description,
      'price_monthly': priceMonthly,
      'room_available': roomAvailable,
      'address': address,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'facilities': jsonEncode(facilities),
    });

    for (final file in newImageFiles) {
      formData.files.add(
        MapEntry(
          'images',
          await MultipartFile.fromFile(
            file.path,
            filename: file.path.split('/').last,
          ),
        ),
      );
    }

    final response = await _apiClient.dio.put(
      ApiEndpoints.ownerPropertyById(id),
      data: formData,
    );
    return PropertyModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<PropertyModel> updateAvailability({
    required int id,
    required bool isAvailable,
    required int roomAvailable,
  }) async {
    final response = await _apiClient.dio.patch(
      ApiEndpoints.ownerPropertyAvailability(id),
      data: {
        'is_available': isAvailable,
        'room_available': roomAvailable,
      },
    );
    return PropertyModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<void> deleteProperty(int id) async {
    await _apiClient.dio.delete(ApiEndpoints.ownerPropertyById(id));
  }
}
