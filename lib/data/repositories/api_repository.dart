import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../models/shift_report_model.dart';
import '../repositories/app_repository.dart';
import '../../core/services/api_client.dart';

/// Live repository that talks to the Node.js + MongoDB backend via REST.
class ApiRepository implements AppRepository {
  final ApiClient _client;

  ApiRepository(this._client);

  Dio get _dio => _client.dio;

  // ── Helpers ───────────────────────────────────────────────────
  String _errorMessage(dynamic err) {
    if (err is DioException && err.response?.data is Map) {
      return (err.response!.data as Map)['error'] as String? ??
          'An error occurred';
    }
    return 'Network error. Please check your connection.';
  }

  // ── Init ──────────────────────────────────────────────────────
  @override
  Future<void> init() async {
    await _client.init();
  }

  // ── Auth ──────────────────────────────────────────────────────
  @override
  Future<LoginResult> login(String username, String password) async {
    try {
      final resp = await _dio.post('/auth/login', data: {
        'username': username,
        'password': password,
      });
      final token = resp.data['token'] as String;
      final user = AppUser.fromJson(resp.data['user'] as Map<String, dynamic>);
      await _client.setToken(token);
      return LoginResult.success(user, token: token);
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['isPending'] == true) {
        return const LoginResult.pending();
      }
      return LoginResult.failure(_errorMessage(e));
    } catch (_) {
      return const LoginResult.failure('Login failed. Please try again.');
    }
  }

  @override
  Future<void> logout() async {
    await _client.clearToken();
  }

  @override
  Future<String?> register({
    required String username,
    required String password,
    required String email,
    required String name,
    required String role,
  }) async {
    try {
      await _dio.post('/auth/register', data: {
        'username': username,
        'password': password,
        'email': email,
        'name': name,
        'role': role,
      });
      return null; // success
    } on DioException catch (e) {
      return _errorMessage(e);
    } catch (_) {
      return 'Registration failed. Please try again.';
    }
  }

  @override
  Future<String?> sendCredentialsByEmail(String email) async {
    try {
      await _dio.post('/auth/forgot-password', data: {'email': email});
      return null;
    } on DioException catch (e) {
      return _errorMessage(e);
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  // ── Users ─────────────────────────────────────────────────────
  @override
  Future<List<AppUser>> getAllUsers() async {
    final resp = await _dio.get('/users');
    return (resp.data as List).map((j) => AppUser.fromJson(j as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<AppUser>> getPendingUsers() async {
    final resp = await _dio.get('/users/pending');
    return (resp.data as List).map((j) => AppUser.fromJson(j as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> approveUser(String userId) async {
    await _dio.patch('/users/$userId/approve');
  }

  @override
  Future<void> rejectUser(String userId) async {
    await _dio.patch('/users/$userId/reject');
  }

  @override
  Future<void> setUserActive(String userId, bool isActive) async {
    await _dio.patch('/users/$userId/active', data: {'isActive': isActive});
  }

  @override
  Future<List<AppUser>> getEmployees() async {
    final resp = await _dio.get('/reports/employees');
    return (resp.data as List).map((j) => AppUser.fromJson(j as Map<String, dynamic>)).toList();
  }

  // ── Reports ───────────────────────────────────────────────────
  @override
  Future<List<ShiftReport>> getAllReports() async {
    final resp = await _dio.get('/reports');
    return (resp.data as List)
        .map((j) => ShiftReport.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ShiftReport>> getReportsByEmployee(String employeeId) async {
    final resp = await _dio.get('/reports', queryParameters: {'employeeId': employeeId});
    return (resp.data as List)
        .map((j) => ShiftReport.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ShiftReport>> getReportsByDateRange(DateTime start, DateTime end,
      {String? employeeId, int? shiftNumber}) async {
    final params = <String, dynamic>{
      'startDate': start.toIso8601String(),
      'endDate': end.toIso8601String(),
      'employeeId': ?employeeId,
      'shiftNumber': ?shiftNumber,
    };
    final resp = await _dio.get('/reports', queryParameters: params);
    return (resp.data as List)
        .map((j) => ShiftReport.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<bool> isDuplicateReport(String employeeId, DateTime date, int shiftNumber,
      {String? excludeReportId}) async {
    // Handled server-side via unique index — returns 409 on submit
    return false;
  }

  @override
  Future<ShiftReport> submitReport(ShiftReport report) async {
    final resp = await _dio.post('/reports', data: report.toJson());
    return ShiftReport.fromJson(resp.data as Map<String, dynamic>);
  }

  @override
  Future<ShiftReport> updateReport(ShiftReport report) async {
    final resp = await _dio.patch('/reports/${report.id}', data: report.toJson());
    return ShiftReport.fromJson(resp.data as Map<String, dynamic>);
  }

  @override
  Future<ShiftReport> updateReportStatus(
      String reportId, ReportStatus status, String adminName,
      {String? notes}) async {
    final resp = await _dio.patch('/reports/$reportId/status', data: {
      'status': status.value,
      'notes': ?notes,
    });
    return ShiftReport.fromJson(resp.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteReport(String reportId) async {
    await _dio.delete('/reports/$reportId');
  }
}
