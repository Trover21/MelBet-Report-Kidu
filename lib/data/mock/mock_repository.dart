import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/shift_report_model.dart';
import '../../core/utils/app_utils.dart';

/// Mock data repository. Simulates a real backend with SharedPreferences.
/// In production, replace with HTTP calls to Node.js API.
class MockRepository {
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
      passwordHash: 'admin123', // Plain text for mock only
      role: UserRole.admin,
    ),
    const AppUser(
      id: 'emp-001',
      name: 'Alem Tadesse',
      username: 'alem',
      passwordHash: 'emp123',
      role: UserRole.employee,
    ),
    const AppUser(
      id: 'emp-002',
      name: 'Biruk Haile',
      username: 'biruk',
      passwordHash: 'emp123',
      role: UserRole.employee,
    ),
    const AppUser(
      id: 'emp-003',
      name: 'Chaltu Bekele',
      username: 'chaltu',
      passwordHash: 'emp123',
      role: UserRole.employee,
    ),
  ];

  final List<AppUser> _users = List.from(_seedUsers);
  List<ShiftReport> _reports = [];
  AppUser? _currentUser;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await _loadFromPrefs();
    if (_reports.isEmpty) {
      _reports = _generateSeedReports();
      await _saveReports();
    }
  }

  // ── Authentication ─────────────────────────────────────────────
  Future<AppUser?> login(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final user = _users.where((u) =>
      u.username.toLowerCase() == username.toLowerCase() &&
      u.passwordHash == password &&
      u.isActive
    ).firstOrNull;
    if (user != null) _currentUser = user;
    return user;
  }

  AppUser? get currentUser => _currentUser;

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_id');
  }

  // ── Reports CRUD ───────────────────────────────────────────────
  Future<List<ShiftReport>> getAllReports() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_reports);
  }

  Future<List<ShiftReport>> getReportsByEmployee(String employeeId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _reports.where((r) => r.employeeId == employeeId).toList();
  }

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

  Future<bool> isDuplicateReport(
      String employeeId, DateTime date, int shiftNumber) async {
    return _reports.any((r) =>
        r.employeeId == employeeId &&
        r.operatingDate.year == date.year &&
        r.operatingDate.month == date.month &&
        r.operatingDate.day == date.day &&
        r.shiftNumber == shiftNumber);
  }

  Future<ShiftReport> submitReport(ShiftReport report) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final newReport = report.copyWith(id: _uuid.v4());
    _reports.add(newReport);
    await _saveReports();
    return newReport;
  }

  Future<ShiftReport> updateReportStatus(
      String reportId, ReportStatus status, String adminName) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final idx = _reports.indexWhere((r) => r.id == reportId);
    if (idx < 0) throw Exception('Report not found');
    final updated = _reports[idx].copyWith(
      status: status,
      lastModifiedAt: DateTime.now(),
    );
    _reports[idx] = updated;
    await _saveReports();
    return updated;
  }

  Future<List<AppUser>> getEmployees() async {
    return _users.where((u) => u.role == UserRole.employee).toList();
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

  // ── Seed Data Generator ────────────────────────────────────────
  List<ShiftReport> _generateSeedReports() {
    final rnd = Random(42);
    final reports = <ShiftReport>[];
    final employees = _users.where((u) => u.role == UserRole.employee).toList();
    final now = DateTime.now();

    // Generate 14 days of data
    for (int day = 13; day >= 0; day--) {
      final date = DateTime(now.year, now.month, now.day - day);

      for (int shift = 1; shift <= 3; shift++) {
        // Occasionally skip a shift to demo missing reports
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
