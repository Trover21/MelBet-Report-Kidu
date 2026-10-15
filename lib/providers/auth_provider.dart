import 'package:flutter/foundation.dart';
import '../data/models/user_model.dart';
import '../data/repositories/app_repository.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AppRepository _repo;
  AuthState _state = AuthState.initial;
  AppUser? _user;
  String? _errorMessage;

  AuthProvider(this._repo);

  AuthState get state => _state;
  AppUser? get user => _user;
  String? get errorMessage => _errorMessage;

  /// True if user has admin OR manager role (both get privileged UI access)
  bool get isPrivileged => _user?.role.isPrivileged ?? false;

  /// Strictly true only if user is Admin (for approval operations)
  bool get isStrictAdmin => _user?.role == UserRole.admin;

  /// Kept for backward compat — screens that check isAdmin should now check isPrivileged
  bool get isAdmin => isPrivileged;

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
      final res = await _repo.login(username, password);
      if (res.success && res.user != null) {
        _user = res.user;
        _state = AuthState.authenticated;
        notifyListeners();
        return true;
      } else {
        _errorMessage = res.error ?? 'Invalid username or password';
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

  /// Returns null on success or an error message string.
  Future<String?> register({
    required String username,
    required String password,
    required String email,
    required String name,
    required String role, // 'employee' | 'manager'
  }) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final error = await _repo.register(
        username: username,
        password: password,
        email: email,
        name: name,
        role: role,
      );
      _state = AuthState.unauthenticated;
      notifyListeners();
      return error;
    } catch (e) {
      _state = AuthState.unauthenticated;
      notifyListeners();
      return 'Registration failed. Please try again.';
    }
  }

  Future<String?> sendForgotPasswordEmail(String email) async {
    try {
      return await _repo.sendCredentialsByEmail(email);
    } catch (e) {
      return 'Something went wrong. Please try again.';
    }
  }

  List<AppUser> _allUsers = [];
  List<AppUser> _pendingUsers = [];

  List<AppUser> get allUsers => _allUsers;
  List<AppUser> get pendingUsers => _pendingUsers;

  Future<void> loadAllUsers() async {
    try {
      _allUsers = await _repo.getAllUsers();
      _pendingUsers = _allUsers.where((u) => !u.isApproved).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadPendingUsers() async {
    await loadAllUsers();
  }

  Future<bool> approveUser(String userId) async {
    try {
      await _repo.approveUser(userId);
      await loadAllUsers();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> setUserActive(String userId, bool isActive) async {
    try {
      await _repo.setUserActive(userId, isActive);
      await loadAllUsers();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> rejectUser(String userId) async {
    try {
      await _repo.rejectUser(userId);
      await loadAllUsers();
      return true;
    } catch (e) {
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
