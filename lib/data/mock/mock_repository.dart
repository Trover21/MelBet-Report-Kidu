import 'dart:convert';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/shift_report_model.dart';
import '../models/team_request_model.dart';
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
    int teamNumber = 1,
    String? teamName,
    List<String>? teams,
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

    String primaryTeam = 'Team 1';
    List<String> userTeams = ['Team 1'];

    if (assignedRole == UserRole.manager) {
      if (teams != null && teams.isNotEmpty) {
        userTeams = List.from(teams);
        primaryTeam = userTeams.first;
      } else if (teamName != null && teamName.isNotEmpty) {
        primaryTeam = teamName;
        userTeams = [primaryTeam];
      }
    } else {
      if (teamName != null && teamName.isNotEmpty) {
        primaryTeam = teamName;
      } else if (teams != null && teams.isNotEmpty) {
        primaryTeam = teams.first;
      } else {
        primaryTeam = 'Team $teamNumber';
      }
      userTeams = [primaryTeam];
    }

    final newUser = AppUser(
      id: _uuid.v4(),
      name: name,
      username: username,
      passwordHash: password,
      role: assignedRole,
      email: email,
      teamNumber: teamNumber,
      teamName: primaryTeam,
      teams: userTeams,
      isApproved: false, // Requires admin approval
      isActive: true,
    );
    _users.add(newUser);
    await _saveUsers();
    return null; // success
  }

  // ── Password Change ─────────────────────────────────────────────
  @override
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final prefs = await SharedPreferences.getInstance();
    final curId = prefs.getString('current_user_id');
    final user = _users.firstWhereOrNull((u) => u.id == curId);
    if (user == null) return 'User not found';
    if (user.passwordHash != currentPassword) return 'Current password is incorrect';
    if (newPassword.length < 6) return 'Password must be at least 6 characters';

    final idx = _users.indexWhere((u) => u.id == curId);
    _users[idx] = user.copyWith(passwordHash: newPassword);
    await _saveUsers();
    return null;
  }

  // ── Teams & Requests ──────────────────────────────────────────
  final List<String> _dynamicTeams = ['Team 1', 'Team 2', 'Team 3'];
  final List<TeamRequest> _mockTeamRequests = [];

  @override
  Future<List<String>> getTeams() async {
    return List.from(_dynamicTeams);
  }

  @override
  Future<String?> addTeam(String name, {String? description}) async {
    final clean = name.trim();
    if (clean.isEmpty) return 'Team name is required';
    if (_dynamicTeams.contains(clean)) return 'Team already exists';
    _dynamicTeams.add(clean);
    return null;
  }

  @override
  Future<String?> removeTeam(String name) async {
    _dynamicTeams.remove(name);
    return null;
  }

  @override
  Future<String?> removeManagerTeam(String teamName) async {
    if (_currentUser == null) return 'Not authenticated';
    final curTeams = List<String>.from(_currentUser!.teams);
    if (curTeams.length <= 1) {
      return 'You must manage at least one team';
    }
    curTeams.remove(teamName);
    final newPrimary = _currentUser!.teamName == teamName
        ? (curTeams.isNotEmpty ? curTeams.first : 'Team 1')
        : _currentUser!.teamName;
    _currentUser = _currentUser!.copyWith(teams: curTeams, teamName: newPrimary);

    final idx = _users.indexWhere((u) => u.id == _currentUser!.id);
    if (idx >= 0) {
      _users[idx] = _currentUser!;
      await _saveUsers();
    }
    return null;
  }

  @override
  Future<String?> requestTeams({
    required List<String> requestedTeams,
    String? reason,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final curId = prefs.getString('current_user_id') ?? 'mgr-001';
    final user = _users.firstWhereOrNull((u) => u.id == curId);

    _mockTeamRequests.add(
      TeamRequest(
        id: _uuid.v4(),
        userId: user?.id ?? curId,
        userName: user?.name ?? 'Manager',
        requestedTeams: requestedTeams,
        reason: reason ?? '',
        createdAt: DateTime.now(),
      ),
    );
    return null;
  }

  @override
  Future<List<TeamRequest>> getTeamRequests() async {
    return List.from(_mockTeamRequests);
  }

  @override
  Future<String?> approveTeamRequest(String requestId) async {
    final idx = _mockTeamRequests.indexWhere((r) => r.id == requestId);
    if (idx < 0) return 'Request not found';
    final req = _mockTeamRequests[idx];
    _mockTeamRequests[idx] = TeamRequest(
      id: req.id,
      userId: req.userId,
      userName: req.userName,
      requestedTeams: req.requestedTeams,
      reason: req.reason,
      status: 'approved',
      reviewedBy: 'Admin',
      reviewedAt: DateTime.now(),
      createdAt: req.createdAt,
    );

    // Add teams to manager's user
    final uIdx = _users.indexWhere((u) => u.id == req.userId);
    if (uIdx >= 0) {
      final curTeams = Set<String>.from(_users[uIdx].teams);
      curTeams.addAll(req.requestedTeams);
      _users[uIdx] = _users[uIdx].copyWith(teams: curTeams.toList());
      await _saveUsers();
    }
    return null;
  }

  @override
  Future<String?> rejectTeamRequest(String requestId) async {
    final idx = _mockTeamRequests.indexWhere((r) => r.id == requestId);
    if (idx < 0) return 'Request not found';
    final req = _mockTeamRequests[idx];
    _mockTeamRequests[idx] = TeamRequest(
      id: req.id,
      userId: req.userId,
      userName: req.userName,
      requestedTeams: req.requestedTeams,
      reason: req.reason,
      status: 'rejected',
      reviewedBy: 'Admin',
      reviewedAt: DateTime.now(),
      createdAt: req.createdAt,
    );
    return null;
  }

  @override
  Future<String?> cancelTeamRequest(String requestId) async {
    _mockTeamRequests.removeWhere((r) => r.id == requestId);
    return null;
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

  @override
  Future<String?> deleteUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _users.indexWhere((u) => u.id == userId);
    if (idx < 0) return 'User not found';
    if (_users[idx].role == UserRole.admin) {
      return 'Cannot delete an administrator account';
    }
    _users.removeAt(idx);
    await _saveUsers();
    return null;
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
      {String? employeeId, int? shiftNumber, String? teamName}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _reports.where((r) {
      final inRange = !r.operatingDate.isBefore(
              DateTime(start.year, start.month, start.day)) &&
          !r.operatingDate
              .isAfter(DateTime(end.year, end.month, end.day, 23, 59, 59));
      final empMatch = employeeId == null || r.employeeId == employeeId;
      final shiftMatch = shiftNumber == null || r.shiftNumber == shiftNumber;
      final teamMatch = teamName == null ||
          r.teamName.toLowerCase() == teamName.toLowerCase() ||
          'Team ${r.teamNumber}'.toLowerCase() == teamName.toLowerCase();
      return inRange && empMatch && shiftMatch && teamMatch;
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
          expectedAmount: 0,
          actualAmount: 0,
          deviation: 0,
          submittedAt: date.add(Duration(hours: shift * 8)),
          status: day > 2 ? ReportStatus.approved : ReportStatus.submitted,
        ));
      }
    }
    return reports;
  }
}
