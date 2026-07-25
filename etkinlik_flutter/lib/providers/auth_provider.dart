import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _currentUser != null;
  bool get isOrganizer => _currentUser?.isOrganizer ?? false;

  AuthProvider() {
    initAuth();
  }

  Future<void> initAuth() async {
    _isLoading = true;
    notifyListeners();
//uygulamayı kapatıp açtığında
    final token = await ApiService.getToken();
    if (token != null) {
      _currentUser = await ApiService.getProfile();
    }

    _isLoading = false;
    _isInitialized = true;
    notifyListeners();
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    final result = await ApiService.login(username, password);
    if (result['success'] == true) {
      _currentUser = await ApiService.getProfile();
    }

    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirm,
    required String role,
    String? firstName,
    String? lastName,
    String? phone,
    String? bio,
  }) async {
    _isLoading = true;
    notifyListeners();

    final result = await ApiService.register(
      username: username,
      email: email,
      password: password,
      passwordConfirm: passwordConfirm,
      role: role,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      bio: bio,
    );

    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<void> logout() async {
    await ApiService.removeToken();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    _currentUser = await ApiService.getProfile();
    notifyListeners();
  }

  Future<Map<String, dynamic>> becomeOrganizer() async {
    _isLoading = true;
    notifyListeners();

    final res = await ApiService.becomeOrganizer();
    if (res['success'] == true && res['user'] != null) {
      _currentUser = res['user'];
    }

    _isLoading = false;
    notifyListeners();
    return res;
  }
}
