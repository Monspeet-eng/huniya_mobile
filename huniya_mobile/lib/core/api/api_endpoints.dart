
import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiEndpoints {
  // Konfigurasi alamat backend
  static String get baseHost {
    if (kIsWeb) {
      return 'http://localhost:8080';
    }

    if (Platform.isAndroid) {
      // IP laptop pada jaringan Wi-Fi saat ini
      return 'http://192.168.100.13:8080';
    }

    return 'http://localhost:8080';
  }

  static String get baseUrl => '$baseHost/api/v1';

  // Auth Endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String me = '/auth/me';

  // User Property & Wishlist Endpoints
  static const String properties = '/properties';
  static const String nearbyProperties = '/properties/nearby';
  static String propertyDetail(int id) => '/properties/$id';
  static const String wishlists = '/wishlists';
  static String toggleWishlist(int propertyId) => '/wishlists/$propertyId';

  // Owner Property Management Endpoints
  static const String ownerProperties = '/owner/properties';
  static String ownerPropertyById(int id) => '/owner/properties/$id';
  static String ownerPropertyAvailability(int id) =>
      '/owner/properties/$id/availability';

  // Wallet Endpoints
  static const String wallet = '/wallet';
  static const String walletTopUp = '/wallet/topup';
  static const String walletTransactions = '/wallet/transactions';

  // Rental & Reminders Endpoints
  static const String rentals = '/rentals';
  static String payRental(int id) => '/rentals/$id/pay';
  static const String rentalReminders = '/rentals/reminders';

  // Boost & Recommendations Endpoints
  static const String recommendedProperties = '/properties/recommended';
  static String ownerPropertyBoost(int id) => '/owner/properties/$id/boost';

  // Helper untuk mengubah path relatif '/uploads/...' menjadi full URL
  static String resolveImageUrl(String path) {
    if (path.isEmpty) return '';

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    return '$baseHost$path';
  }
}
