import 'package:flutter/foundation.dart';
import '../data/models/user_model.dart';
import '../data/mock/mock_repository.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final MockRepository _repo;
  AuthState _state = AuthState.initial;
  AppUser? _user;
  String? _errorMessage;

  AuthProvider(this._repo);

  AuthState get state => _state;
  AppUser? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAdmin => _user?.role == UserRole.admin;
  bool get isAuthenticated => _state == AuthState.authenticated;

  Future<void> init() async {
    await _repo.init();
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _repo.login(username, password);
      if (user != null) {
        _user = user;
        _state = AuthState.authenticated;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Invalid username or password';
        _state = AuthState.unauthenticated;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Login failed. Please try again.';
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    _user = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }
}
