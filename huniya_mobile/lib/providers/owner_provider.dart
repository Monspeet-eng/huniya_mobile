import 'dart:io';
import 'package:flutter/material.dart';
import '../core/api/api_client.dart';
import '../data/models/property_model.dart';
import '../data/services/property_service.dart';

class OwnerProvider extends ChangeNotifier {
  final PropertyService _propertyService = PropertyService();

  List<PropertyModel> _myProperties = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<PropertyModel> get myProperties => _myProperties;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalProperties => _myProperties.length;
  int get availablePropertiesCount =>
      _myProperties.where((p) => p.isAvailable && p.roomAvailable > 0).length;
  int get fullPropertiesCount =>
      _myProperties.where((p) => !p.isAvailable || p.roomAvailable == 0).length;

  Future<void> fetchOwnerProperties() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _myProperties = await _propertyService.getOwnerProperties();
    } catch (e) {
      _errorMessage = ApiClient.extractErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createProperty({
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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _propertyService.createProperty(
        title: title,
        type: type,
        description: description,
        priceMonthly: priceMonthly,
        roomAvailable: roomAvailable,
        address: address,
        city: city,
        latitude: latitude,
        longitude: longitude,
        facilities: facilities,
        imageFiles: imageFiles,
      );
      await fetchOwnerProperties();
      return true;
    } catch (e) {
      _errorMessage = ApiClient.extractErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProperty({
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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _propertyService.updateProperty(
        id: id,
        title: title,
        type: type,
        description: description,
        priceMonthly: priceMonthly,
        roomAvailable: roomAvailable,
        address: address,
        city: city,
        latitude: latitude,
        longitude: longitude,
        facilities: facilities,
        newImageFiles: newImageFiles,
      );
      await fetchOwnerProperties();
      return true;
    } catch (e) {
      _errorMessage = ApiClient.extractErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleAvailability(PropertyModel prop) async {
    final newStatus = !prop.isAvailable;
    final newRooms =
        newStatus ? (prop.roomAvailable == 0 ? 1 : prop.roomAvailable) : 0;

    try {
      await _propertyService.updateAvailability(
        id: prop.id,
        isAvailable: newStatus,
        roomAvailable: newRooms,
      );
      await fetchOwnerProperties();
      return true;
    } catch (e) {
      _errorMessage = ApiClient.extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProperty(int id) async {
    try {
      await _propertyService.deleteProperty(id);
      _myProperties.removeWhere((p) => p.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ApiClient.extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }
}
