import 'package:flutter/material.dart';
import '../core/api/api_client.dart';
import '../data/models/wallet_model.dart';
import '../data/models/rental_model.dart';
import '../data/models/property_model.dart';
import '../data/services/payment_service.dart';

class PaymentProvider extends ChangeNotifier {
  final PaymentService _service = PaymentService();

  WalletModel? _wallet;
  List<WalletTransactionModel> _transactions = [];
  List<RentalModel> _userRentals = [];
  List<RentalModel> _dueReminders = [];
  List<PropertyModel> _recommendedProperties = [];

  bool _isLoading = false;
  String? _errorMessage;

  WalletModel? get wallet => _wallet;
  List<WalletTransactionModel> get transactions => _transactions;
  List<RentalModel> get userRentals => _userRentals;
  List<RentalModel> get dueReminders => _dueReminders;
  List<PropertyModel> get recommendedProperties => _recommendedProperties;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchWallet() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _wallet = await _service.getWallet();
      _transactions = await _service.getTransactions();
    } catch (e) {
      _errorMessage = ApiClient.extractErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> topUp(double amount) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.topUp(amount);
      await fetchWallet();
      return true;
    } catch (e) {
      _errorMessage = ApiClient.extractErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchRemindersAndRentals() async {
    try {
      _dueReminders = await _service.getDueReminders();
      _userRentals = await _service.getUserRentals();
      notifyListeners();
    } catch (e) {
      _errorMessage = ApiClient.extractErrorMessage(e);
      notifyListeners();
    }
  }

  Future<bool> createRental(int propertyId, int months) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.createRental(propertyId, months);
      await fetchWallet();
      await fetchRemindersAndRentals();
      return true;
    } catch (e) {
      _errorMessage = ApiClient.extractErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> payRent(int rentalId, int months) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.payRent(rentalId, months);
      await fetchWallet();
      await fetchRemindersAndRentals();
      return true;
    } catch (e) {
      _errorMessage = ApiClient.extractErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchRecommendations() async {
    try {
      _recommendedProperties = await _service.getRecommendedProperties();
      notifyListeners();
    } catch (e) {
      _errorMessage = ApiClient.extractErrorMessage(e);
      notifyListeners();
    }
  }

  Future<bool> purchaseBoost(int propertyId, int months) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.purchaseBoost(propertyId, months);
      await fetchWallet();
      return true;
    } catch (e) {
      _errorMessage = ApiClient.extractErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}

