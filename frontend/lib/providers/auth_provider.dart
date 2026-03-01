// lib/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  User? _user;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  bool get isInitialized => _isInitialized;
  String? get error => _error;

  Future<void> initialize() async {
    final token = await _storage.read(key: 'auth_token');
    if (token != null) {
      _api.setToken(token);
      try {
        final data = await _api.getMe();
        if (data['success'] == true && data['profile'] != null) {
          _user = User.fromJson(data['profile'] as Map<String, dynamic>);
        }
      } catch (_) {
        await _storage.delete(key: 'auth_token');
        _api.setToken(null);
      }
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<String?> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.login(username: username, password: password);
      final token = data['token'] as String;
      await _storage.write(key: 'auth_token', value: token);
      _api.setToken(token);

      final profile = await _api.getMe();
      if (profile['success'] == true && profile['profile'] != null) {
        _user = User.fromJson(profile['profile'] as Map<String, dynamic>);
      } else {
        _user = User(
          userId: data['user_id'] ?? '',
          username: data['username'] ?? username,
          email: '',
          fullName: data['full_name'] ?? '',
          expertiseLevel: data['expertise_level'] ?? 'tourist',
          ageGroup: 'adult',
          totalSessions: 0,
        );
      }
      _isLoading = false;
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return e.message;
    } catch (e) {
      // ✅ FIX 2: _api.baseUrl is now valid (getter is on ApiService)
      _error = 'Connection failed. Check server is running at ${_api.baseUrl}';
      _isLoading = false;
      notifyListeners();
      return _error;
    }
  }

  Future<String?> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
    required String ageGroup,
    required String expertiseLevel,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _api.register(
        username: username,
        email: email,
        password: password,
        fullName: fullName,
        ageGroup: ageGroup,
        expertiseLevel: expertiseLevel,
      );
      _isLoading = false;
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return e.message;
    } catch (e) {
      _error = 'Connection failed. Is the server running?';
      _isLoading = false;
      notifyListeners();
      return _error;
    }
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (_) {}
    await _storage.delete(key: 'auth_token');
    _api.setToken(null);
    _user = null;
    notifyListeners();
  }

  Future<String?> updateExpertiseLevel(String level) async {
    try {
      final result = await _api.updateProfile({'expertise_level': level});
      if (result['success'] == true && _user != null) {
        _user = User(
          userId: _user!.userId,
          username: _user!.username,
          email: _user!.email,
          fullName: _user!.fullName,
          expertiseLevel: level,
          ageGroup: _user!.ageGroup,
          lastLogin: _user!.lastLogin,
          totalSessions: _user!.totalSessions,
        );
        notifyListeners();
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> changePassword(String oldPwd, String newPwd) async {
    try {
      final result = await _api.changePassword(
        oldPassword: oldPwd,
        newPassword: newPwd,
      );
      if (result['success'] != true) return result['error'];
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }
}