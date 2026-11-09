import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api/api_client.dart';
import '../data/models/user_model.dart';
import '../data/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  static const String _userCacheKey = 'huniya_user_cache';

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  Future<UserModel?> checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(ApiClient.tokenKey);
    if (token == null || token.isEmpty) {
      _user = null;
      notifyListeners();
      return null;
    }

    try {
      final profile = await _authService.getMe();
      _user = profile;
      await prefs.setString(_userCacheKey, jsonEncode(profile.toJson()));
      notifyListeners();
      return profile;
    } catch (_) {
      final cached = prefs.getString(_userCacheKey);
      if (cached != null) {
        _user = UserModel.fromJson(jsonDecode(cached) as Map<String, dynamic>);
        notifyListeners();
        return _user;
      }
      await logout();
      return null;
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.login(email: email, password: password);
      await _persistAuth(result);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ApiClient.extractErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
        role: role,
      );
      await _persistAuth(result);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ApiClient.extractErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _persistAuth(AuthResult result) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiClient.tokenKey, result.accessToken);
    await prefs.setString(_userCacheKey, jsonEncode(result.user.toJson()));
    _user = result.user;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiClient.tokenKey);
    await prefs.remove(_userCacheKey);
    _user = null;
    notifyListeners();
  }
}
