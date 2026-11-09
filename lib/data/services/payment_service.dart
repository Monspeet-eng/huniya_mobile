import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../models/wallet_model.dart';
import '../models/rental_model.dart';
import '../models/property_model.dart';

class PaymentService {
  final ApiClient _apiClient = ApiClient();

  // Wallet
  Future<WalletModel> getWallet() async {
    final response = await _apiClient.dio.get(ApiEndpoints.wallet);
    return WalletModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> topUp(double amount) async {
    await _apiClient.dio.post(ApiEndpoints.walletTopUp, data: {'amount': amount});
  }

  Future<List<WalletTransactionModel>> getTransactions() async {
    final response = await _apiClient.dio.get(ApiEndpoints.walletTransactions);
    final List<dynamic> raw = response.data['data'] ?? [];
    return raw.map((e) => WalletTransactionModel.fromJson(e)).toList();
  }

  // Rentals
  Future<List<RentalModel>> getUserRentals() async {
    final response = await _apiClient.dio.get(ApiEndpoints.rentals);
    final List<dynamic> raw = response.data['data'] ?? [];
    return raw.map((e) => RentalModel.fromJson(e)).toList();
  }

  Future<void> createRental(int propertyId, int monthsCount) async {
    await _apiClient.dio.post(ApiEndpoints.rentals, data: {
      'property_id': propertyId,
      'months_count': monthsCount,
    });
  }

  Future<void> payRent(int rentalId, int monthsCount) async {
    await _apiClient.dio.post(ApiEndpoints.payRental(rentalId), data: {
      'months_count': monthsCount,
    });
  }

  Future<List<RentalModel>> getDueReminders() async {
    final response = await _apiClient.dio.get(ApiEndpoints.rentalReminders);
    final List<dynamic> raw = response.data['data'] ?? [];
    return raw.map((e) => RentalModel.fromJson(e)).toList();
  }

  // Boost & Recommendations
  Future<List<PropertyModel>> getRecommendedProperties() async {
    final response = await _apiClient.dio.get(ApiEndpoints.recommendedProperties);
    final List<dynamic> raw = response.data['data'] ?? [];
    return raw.map((e) => PropertyModel.fromJson(e)).toList();
  }

  Future<void> purchaseBoost(int propertyId, int monthsCount) async {
    await _apiClient.dio.post(ApiEndpoints.ownerPropertyBoost(propertyId), data: {
      'months_count': monthsCount,
    });
  }
}

