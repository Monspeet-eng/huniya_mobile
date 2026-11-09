import 'package:flutter/material.dart';
import '../core/api/api_client.dart';
import '../core/utils/location_helper.dart';
import '../data/models/property_model.dart';
import '../data/services/property_service.dart';

class PropertyProvider extends ChangeNotifier {
  final PropertyService _propertyService = PropertyService();

  List<PropertyModel> _nearbyProperties = [];
  List<PropertyModel> _allProperties = [];
  List<PropertyModel> _wishlists = [];

  double _currentLat = LocationHelper.defaultLat;
  double _currentLng = LocationHelper.defaultLng;
  String _currentAddressLabel = 'Memuat lokasi GPS...';

  String _selectedType = 'all';
  double _selectedRadius = 5.0;
  double? _minPrice;
  double? _maxPrice;
  String _searchQuery = '';

  bool _isLoading = false;
  String? _errorMessage;

  List<PropertyModel> get nearbyProperties => _nearbyProperties;
  List<PropertyModel> get allProperties => _allProperties;
  List<PropertyModel> get wishlists => _wishlists;
  double get currentLat => _currentLat;
  double get currentLng => _currentLng;
  String get currentAddressLabel => _currentAddressLabel;
  String get selectedType => _selectedType;
  double get selectedRadius => _selectedRadius;
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> initUserLocationAndLoad() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final pos = await LocationHelper.getCurrentPosition();
      _currentLat = pos.latitude;
      _currentLng = pos.longitude;
      _currentAddressLabel = await LocationHelper.getAddressFromLatLng(
        _currentLat,
        _currentLng,
      );
    } catch (e) {
      _currentAddressLabel =
          'Jakarta Pusat (Default - ${e.toString().replaceAll("Exception: ", "")})';
    }

    await Future.wait([
      fetchNearbyProperties(),
      fetchFilteredProperties(),
      fetchWishlists(),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchNearbyProperties() async {
    try {
      _nearbyProperties = await _propertyService.getNearbyProperties(
        lat: _currentLat,
        lng: _currentLng,
        radius: _selectedRadius,
        type: _selectedType,
      );
      notifyListeners();
    } catch (e) {
      _errorMessage = ApiClient.extractErrorMessage(e);
      notifyListeners();
    }
  }

  Future<void> fetchFilteredProperties() async {
    try {
      _allProperties = await _propertyService.getProperties(
        search: _searchQuery,
        type: _selectedType,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
      );
      notifyListeners();
    } catch (e) {
      _errorMessage = ApiClient.extractErrorMessage(e);
      notifyListeners();
    }
  }

  Future<void> applyFilters({
    String? search,
    String? type,
    double? radius,
    double? minPrice,
    double? maxPrice,
  }) async {
    if (search != null) _searchQuery = search;
    if (type != null) _selectedType = type;
    if (radius != null) _selectedRadius = radius;
    _minPrice = minPrice;
    _maxPrice = maxPrice;

    _isLoading = true;
    notifyListeners();

    await Future.wait([
      fetchNearbyProperties(),
      fetchFilteredProperties(),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  Future<PropertyModel?> getDetail(int id) async {
    try {
      return await _propertyService.getPropertyDetail(id);
    } catch (e) {
      _errorMessage = ApiClient.extractErrorMessage(e);
      notifyListeners();
      return null;
    }
  }

  Future<void> fetchWishlists() async {
    try {
      _wishlists = await _propertyService.getWishlists();
      notifyListeners();
    } catch (_) {}
  }

  bool isWishlisted(int propertyId) {
    return _wishlists.any((p) => p.id == propertyId);
  }

  Future<bool> toggleWishlist(int propertyId) async {
    final added = await _propertyService.toggleWishlist(propertyId);
    await fetchWishlists();
    return added;
  }
}
