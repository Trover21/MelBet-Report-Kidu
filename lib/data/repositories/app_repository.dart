import '../models/user_model.dart';
import '../models/shift_report_model.dart';

/// Result object returned from login attempts
class LoginResult {
  final bool success;
  final bool isPending;
  final AppUser? user;
  final String? error;
  final String? token; // JWT token (null in mock mode)

  const LoginResult.success(this.user, {this.token})
      : success = true,
        isPending = false,
        error = null;

  const LoginResult.pending()
      : success = false,
        isPending = true,
        user = null,
        token = null,
        error =
            'Your account is pending administrator approval. Please contact an admin or wait for approval before signing in.';

  const LoginResult.failure(this.error)
      : success = false,
        isPending = false,
        user = null,
        token = null;
}

/// Abstract repository interface — implemented by both MockRepository
/// (offline / SharedPreferences) and ApiRepository (MongoDB backend).
abstract class AppRepository {
  Future<void> init();

  // ── Auth ──────────────────────────────────────────────────────
  Future<LoginResult> login(String username, String password);
  Future<void> logout();
  Future<String?> register({
    required String username,
    required String password,
    required String email,
    required String name,
    required String role, // 'employee' | 'manager'
  });
  Future<String?> sendCredentialsByEmail(String email);

  // ── Users ─────────────────────────────────────────────────────
  Future<List<AppUser>> getAllUsers();
  Future<List<AppUser>> getPendingUsers();
  Future<void> approveUser(String userId);
  Future<void> rejectUser(String userId);
  Future<void> setUserActive(String userId, bool isActive);
  Future<List<AppUser>> getEmployees();

  // ── Reports ───────────────────────────────────────────────────
  Future<List<ShiftReport>> getAllReports();
  Future<List<ShiftReport>> getReportsByEmployee(String employeeId);
  Future<List<ShiftReport>> getReportsByDateRange(DateTime start, DateTime end,
      {String? employeeId, int? shiftNumber});
  Future<bool> isDuplicateReport(String employeeId, DateTime date, int shiftNumber,
      {String? excludeReportId});
  Future<ShiftReport> submitReport(ShiftReport report);
  Future<ShiftReport> updateReport(ShiftReport report);
  Future<ShiftReport> updateReportStatus(
      String reportId, ReportStatus status, String adminName,
      {String? notes});
  Future<void> deleteReport(String reportId);
}
