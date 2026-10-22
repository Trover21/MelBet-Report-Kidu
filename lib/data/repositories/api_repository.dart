import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../models/shift_report_model.dart';
import '../models/team_request_model.dart';
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
    int teamNumber = 1,
    String? teamName,
    List<String>? teams,
  }) async {
    try {
      await _dio.post('/auth/register', data: {
        'username': username,
        'password': password,
        'email': email,
        'name': name,
        'role': role,
        'teamNumber': teamNumber,
        'teamName': ?teamName,
        'teams': ?teams,
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

  @override
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.post('/auth/change-password', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
      return null;
    } on DioException catch (e) {
      return _errorMessage(e);
    } catch (_) {
      return 'Failed to change password. Please try again.';
    }
  }

  // ── Teams & Requests ──────────────────────────────────────────
  @override
  Future<List<String>> getTeams() async {
    try {
      final resp = await _dio.get('/teams');
      final list = resp.data['teams'] as List<dynamic>? ?? [];
      return list.map((e) => e.toString()).toList();
    } catch (_) {
      return ['Team 1', 'Team 2', 'Team 3'];
    }
  }

  @override
  Future<String?> addTeam(String name, {String? description}) async {
    try {
      await _dio.post('/teams', data: {
        'name': name,
        'description': ?description,
      });
      return null;
    } on DioException catch (e) {
      return _errorMessage(e);
    } catch (_) {
      return 'Failed to add team';
    }
  }

  @override
  Future<String?> removeTeam(String name) async {
    try {
      await _dio.delete('/teams/$name');
      return null;
    } on DioException catch (e) {
      return _errorMessage(e);
    } catch (_) {
      return 'Failed to remove team';
    }
  }

  @override
  Future<String?> removeManagerTeam(String teamName) async {
    try {
      await _dio.delete('/teams/my-team/$teamName');
      return null;
    } on DioException catch (e) {
      return _errorMessage(e);
    } catch (_) {
      return 'Failed to remove team from your managed list';
    }
  }

  @override
  Future<String?> requestTeams({
    required List<String> requestedTeams,
    String? reason,
  }) async {
    try {
      await _dio.post('/teams/request', data: {
        'requestedTeams': requestedTeams,
        'reason': ?reason,
      });
      return null;
    } on DioException catch (e) {
      return _errorMessage(e);
    } catch (_) {
      return 'Failed to submit team request';
    }
  }

  @override
  Future<List<TeamRequest>> getTeamRequests() async {
    try {
      final resp = await _dio.get('/teams/requests');
      final list = resp.data['requests'] as List<dynamic>? ?? [];
      return list.map((e) => TeamRequest.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<String?> approveTeamRequest(String requestId) async {
    try {
      await _dio.post('/teams/requests/$requestId/approve');
      return null;
    } on DioException catch (e) {
      return _errorMessage(e);
    } catch (_) {
      return 'Failed to approve request';
    }
  }

  @override
  Future<String?> rejectTeamRequest(String requestId) async {
    try {
      await _dio.post('/teams/requests/$requestId/reject');
      return null;
    } on DioException catch (e) {
      return _errorMessage(e);
    } catch (_) {
      return 'Failed to reject request';
    }
  }

  @override
  Future<String?> cancelTeamRequest(String requestId) async {
    try {
      await _dio.delete('/teams/requests/$requestId');
      return null;
    } on DioException catch (e) {
      return _errorMessage(e);
    } catch (_) {
      return 'Failed to cancel request';
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
  Future<String?> deleteUser(String userId) async {
    try {
      await _dio.delete('/users/$userId');
      return null;
    } on DioException catch (e) {
      return _errorMessage(e);
    } catch (_) {
      return 'Failed to delete user';
    }
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
      {String? employeeId, int? shiftNumber, String? teamName}) async {
    final params = <String, dynamic>{
      'startDate': start.toIso8601String(),
      'endDate': end.toIso8601String(),
      'employeeId': ?employeeId,
      'shiftNumber': ?shiftNumber,
      'teamName': ?teamName,
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
