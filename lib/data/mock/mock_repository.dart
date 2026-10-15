import 'dart:convert';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/shift_report_model.dart';
import '../repositories/app_repository.dart';
import '../../core/utils/app_utils.dart';

class MockRepository implements AppRepository {
  static final MockRepository _instance = MockRepository._();
  factory MockRepository() => _instance;
  MockRepository._();

  static const _uuid = Uuid();

  // ── Mock Users ─────────────────────────────────────────────────
  static final List<AppUser> _seedUsers = [
    const AppUser(
      id: 'admin-001',
      name: 'Admin User',
      username: 'admin',
      passwordHash: 'admin123',
      role: UserRole.admin,
      email: 'admin@melbet.com',
      isApproved: true,
    ),
    const AppUser(
      id: 'mgr-001',
      name: 'Manager User',
      username: 'manager',
      passwordHash: 'mgr123',
      role: UserRole.manager,
      email: 'manager@melbet.com',
      isApproved: true,
    ),
    const AppUser(
      id: 'emp-001',
      name: 'Alem Tadesse',
      username: 'alem',
      passwordHash: 'emp123',
      role: UserRole.employee,
      email: 'alem@melbet.com',
      isApproved: true,
    ),
    const AppUser(
      id: 'emp-002',
      name: 'Biruk Haile',
      username: 'biruk',
      passwordHash: 'emp123',
      role: UserRole.employee,
      email: 'biruk@melbet.com',
      isApproved: true,
    ),
    const AppUser(
      id: 'emp-003',
      name: 'Chaltu Bekele',
      username: 'chaltu',
      passwordHash: 'emp123',
      role: UserRole.employee,
      email: 'chaltu@melbet.com',
      isApproved: true,
    ),
  ];

  final List<AppUser> _users = List.from(_seedUsers);
  List<ShiftReport> _reports = [];
  AppUser? _currentUser;
  bool _initialized = false;

  @override
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await _loadUsersFromPrefs();
    await _loadFromPrefs();
    if (_reports.isEmpty) {
      _reports = _generateSeedReports();
      await _saveReports();
    }
  }

  // ── Authentication ─────────────────────────────────────────────
  @override
  Future<LoginResult> login(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final user = _users.firstWhereOrNull((u) =>
        u.username.toLowerCase() == username.toLowerCase() &&
        u.passwordHash == password);

    if (user == null) {
      return const LoginResult.failure('Invalid username or password');
    }
    if (!user.isApproved) return const LoginResult.pending();
    if (!user.isActive) {
      return const LoginResult.failure(
          'Your account has been disabled by an administrator. Please contact your manager.');
    }

    _currentUser = user;
    return LoginResult.success(user);
  }

  AppUser? get currentUser => _currentUser;

  @override
  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_id');
  }

  // ── Registration ───────────────────────────────────────────────
  @override
  Future<String?> register({
    required String username,
    required String password,
    required String email,
    required String name,
    required String role,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));

    final usernameTaken =
        _users.any((u) => u.username.toLowerCase() == username.toLowerCase());
    if (usernameTaken) return 'Username is already taken';

    final emailTaken =
        _users.any((u) => u.email?.toLowerCase() == email.toLowerCase());
    if (emailTaken) return 'Email is already registered';

    // Only allow employee or manager self-registration
    final assignedRole = role == 'manager' ? UserRole.manager : UserRole.employee;

    final newUser = AppUser(
      id: _uuid.v4(),
      name: name,
      username: username,
      passwordHash: password,
      role: assignedRole,
      email: email,
      isApproved: false, // Requires admin approval
      isActive: true,
    );
    _users.add(newUser);
    await _saveUsers();
    return null; // success
  }

  // ── Forgot Password ────────────────────────────────────────────
  @override
  Future<String?> sendCredentialsByEmail(String email) async {
    await Future.delayed(const Duration(milliseconds: 700));
    final user = _users.firstWhereOrNull(
        (u) => u.email?.toLowerCase() == email.toLowerCase());
    if (user == null) return 'No account found with that email address';
    return null; // success
  }

  // ── User Management ────────────────────────────────────────────
  @override
  Future<List<AppUser>> getPendingUsers() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _users.where((u) => !u.isApproved).toList();
  }

  @override
  Future<List<AppUser>> getAllUsers() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.from(_users);
  }

  @override
  Future<void> approveUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _users.indexWhere((u) => u.id == userId);
    if (idx < 0) throw Exception('User not found');
    _users[idx] = _users[idx].copyWith(isApproved: true, isActive: true);
    await _saveUsers();
  }

  @override
  Future<void> setUserActive(String userId, bool isActive) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _users.indexWhere((u) => u.id == userId);
    if (idx < 0) throw Exception('User not found');
    _users[idx] = _users[idx].copyWith(isActive: isActive);
    await _saveUsers();
  }

  @override
  Future<void> rejectUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _users.indexWhere((u) => u.id == userId);
    if (idx < 0) throw Exception('User not found');
    _users.removeAt(idx);
    await _saveUsers();
  }

  // ── Reports CRUD ───────────────────────────────────────────────
  @override
  Future<List<ShiftReport>> getAllReports() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_reports);
  }

  @override
  Future<List<ShiftReport>> getReportsByEmployee(String employeeId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _reports.where((r) => r.employeeId == employeeId).toList();
  }

  @override
  Future<List<ShiftReport>> getReportsByDateRange(
      DateTime start, DateTime end,
      {String? employeeId, int? shiftNumber}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _reports.where((r) {
      final inRange = !r.operatingDate.isBefore(
              DateTime(start.year, start.month, start.day)) &&
          !r.operatingDate
              .isAfter(DateTime(end.year, end.month, end.day, 23, 59, 59));
      final empMatch = employeeId == null || r.employeeId == employeeId;
      final shiftMatch = shiftNumber == null || r.shiftNumber == shiftNumber;
      return inRange && empMatch && shiftMatch;
    }).toList();
  }

  @override
  Future<bool> isDuplicateReport(
      String employeeId, DateTime date, int shiftNumber,
      {String? excludeReportId}) async {
    return _reports.any((r) =>
        r.id != excludeReportId &&
        r.employeeId == employeeId &&
        r.operatingDate.year == date.year &&
        r.operatingDate.month == date.month &&
        r.operatingDate.day == date.day &&
        r.shiftNumber == shiftNumber);
  }

  @override
  Future<ShiftReport> submitReport(ShiftReport report) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newReport = report.copyWith(id: _uuid.v4());
    _reports.add(newReport);
    await _saveReports();
    return newReport;
  }

  @override
  Future<ShiftReport> updateReport(ShiftReport report) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final idx = _reports.indexWhere((r) => r.id == report.id);
    if (idx < 0) throw Exception('Report not found');
    final updated = report.copyWith(
      status: ReportStatus.submitted,
      lastModifiedAt: DateTime.now(),
    );
    _reports[idx] = updated;
    await _saveReports();
    return updated;
  }

  @override
  Future<ShiftReport> updateReportStatus(
      String reportId, ReportStatus status, String adminName,
      {String? notes}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final idx = _reports.indexWhere((r) => r.id == reportId);
    if (idx < 0) throw Exception('Report not found');

    final current = _reports[idx];
    final history = List<CorrectionRecord>.from(current.correctionHistory);
    if (notes != null && notes.trim().isNotEmpty) {
      history.add(CorrectionRecord(
        correctedBy: adminName,
        correctedAt: DateTime.now(),
        reason: notes.trim(),
      ));
    }

    final updated = current.copyWith(
      status: status,
      notes: notes ?? current.notes,
      correctionHistory: history,
      lastModifiedAt: DateTime.now(),
    );
    _reports[idx] = updated;
    await _saveReports();
    return updated;
  }

  @override
  Future<void> deleteReport(String reportId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _reports.removeWhere((r) => r.id == reportId);
    await _saveReports();
  }

  @override
  Future<List<AppUser>> getEmployees() async {
    return _users
        .where((u) => u.role == UserRole.employee && u.isApproved)
        .toList();
  }

  // ── Persistence ────────────────────────────────────────────────
  Future<void> _saveReports() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _reports.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList('shift_reports', jsonList);
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('shift_reports');
    if (jsonList != null && jsonList.isNotEmpty) {
      _reports = jsonList
          .map((s) => ShiftReport.fromJson(jsonDecode(s) as Map<String, dynamic>))
          .toList();
    }
  }

  Future<void> _saveUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _users.map((u) => jsonEncode(u.toJson())).toList();
    await prefs.setStringList('app_users', jsonList);
  }

  Future<void> _loadUsersFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('app_users');
    if (jsonList != null && jsonList.isNotEmpty) {
      _users.clear();
      _users.addAll(jsonList
          .map((s) => AppUser.fromJson(jsonDecode(s) as Map<String, dynamic>)));
    }
  }

  // ── Seed Data Generator ────────────────────────────────────────
  List<ShiftReport> _generateSeedReports() {
    final rnd = Random(42);
    final reports = <ShiftReport>[];
    final employees = _users.where((u) => u.role == UserRole.employee).toList();
    final now = DateTime.now();

    for (int day = 13; day >= 0; day--) {
      final date = DateTime(now.year, now.month, now.day - day);

      for (int shift = 1; shift <= 3; shift++) {
        if (rnd.nextDouble() < 0.1) continue;

        final empInShift = employees[rnd.nextInt(employees.length)];
        final initialReddy = 5000 + rnd.nextDouble() * 5000;
        final initialAccount = 1000 + rnd.nextDouble() * 3000;
        final totalDeposit = 10000 + rnd.nextDouble() * 50000;
        final totalWithdrawal = 5000 + rnd.nextDouble() * 30000;
        final endReddy = 4000 + rnd.nextDouble() * 6000;
        final transferToNext = 500 + rnd.nextDouble() * 2000;
        final totalUnprocessed = rnd.nextDouble() * 500;
        final added = rnd.nextDouble() * 200;
        final taken = rnd.nextDouble() * 200;
        final depCompl = rnd.nextDouble() * 300;
        final wdCompl = rnd.nextDouble() * 200;

        final eb = AppUtils.endBalance(
          initialReddy: initialReddy,
          initialAccount: initialAccount,
          totalDeposit: totalDeposit,
          totalWithdrawal: totalWithdrawal,
          totalUnprocessed: totalUnprocessed,
          added: added,
          transferToNext: transferToNext,
          depositComplaintAccepted: depCompl,
          withdrawalComplaintAccepted: wdCompl,
          taken: taken,
        );
        final depComm = AppUtils.depositCommission(totalDeposit);
        final wdComm = AppUtils.withdrawalCommission(totalWithdrawal);
        final totComm = AppUtils.totalCommission(depComm, wdComm);
        final expected = AppUtils.expectedAmount(
          initialReddy: initialReddy,
          initialAccount: initialAccount,
          totalCommission: totComm,
        );
        final actual = AppUtils.actualAmount(
          endReddy: endReddy,
          endBalance: eb,
          transferToNext: transferToNext,
        );
        final dev = AppUtils.shiftDeviation(
            actualAmount: actual, expectedAmount: expected);

        reports.add(ShiftReport(
          id: _uuid.v4(),
          employeeId: empInShift.id,
          employeeName: empInShift.name,
          operatingDate: date,
          shiftNumber: shift,
          initialReddy: initialReddy,
          initialAccount: initialAccount,
          totalDeposit: totalDeposit,
          totalWithdrawal: totalWithdrawal,
          endReddy: endReddy,
          transferToNext: transferToNext,
          depositComplaintAccepted: depCompl,
          withdrawalComplaintAccepted: wdCompl,
          totalUnprocessed: totalUnprocessed,
          added: added,
          taken: taken,
          endBalance: eb,
          depositCommission: depComm,
          withdrawalCommission: wdComm,
          totalCommission: totComm,
          expectedAmount: expected,
          actualAmount: actual,
          deviation: dev,
          submittedAt: date.add(Duration(hours: shift * 8)),
          status: day > 2 ? ReportStatus.approved : ReportStatus.submitted,
        ));
      }
    }
    return reports;
  }
}
