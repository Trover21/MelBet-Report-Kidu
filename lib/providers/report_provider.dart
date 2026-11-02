import 'package:flutter/foundation.dart';
import '../data/models/shift_report_model.dart';
import '../data/models/user_model.dart';
import '../data/repositories/app_repository.dart';
import '../core/utils/app_utils.dart';

class ReportProvider extends ChangeNotifier {
  final AppRepository _repo;

  List<ShiftReport> _reports = [];
  List<AppUser> _employees = [];
  bool _loading = false;
  String? _error;

  // Filter state
  DateTime? _filterStart;
  DateTime? _filterEnd;
  String? _filterEmployeeId;
  int? _filterShift;
  int? _filterTeamNumber;
  String? _filterTeamName;
  List<String>? _restrictedTeams; // null for admin (org-wide), set to assigned teams for manager

  ReportProvider(this._repo);

  List<String>? get restrictedTeams => _restrictedTeams;
  void setRestrictedTeams(List<String>? teams) {
    _restrictedTeams = teams;
    notifyListeners();
  }

  List<ShiftReport> get reports {
    if (_restrictedTeams != null) {
      return _reports.where((r) {
        return _restrictedTeams!.any((t) =>
            t.toLowerCase() == r.teamName.toLowerCase() ||
            t.toLowerCase() == 'Team ${r.teamNumber}'.toLowerCase());
      }).toList();
    }
    return _reports;
  }

  List<ShiftReport> get filteredReports {
    return _reports.where((r) {
      if (_restrictedTeams != null) {
        final matchesRestricted = _restrictedTeams!.any((t) =>
            t.toLowerCase() == r.teamName.toLowerCase() ||
            t.toLowerCase() == 'Team ${r.teamNumber}'.toLowerCase());
        if (!matchesRestricted) return false;
      }
      final inRange = (_filterStart == null ||
              !r.operatingDate.isBefore(_filterStart!)) &&
          (_filterEnd == null || !r.operatingDate.isAfter(_filterEnd!));
      final empMatch = _filterEmployeeId == null || _filterEmployeeId!.isEmpty ||
          r.employeeId == _filterEmployeeId;
      final shiftMatch =
          _filterShift == null || r.shiftNumber == _filterShift;
      final teamMatch = _filterTeamName != null
          ? (r.teamName.toLowerCase() == _filterTeamName!.toLowerCase() ||
              'Team ${r.teamNumber}'.toLowerCase() == _filterTeamName!.toLowerCase())
          : (_filterTeamNumber == null || r.teamNumber == _filterTeamNumber);
      return inRange && empMatch && shiftMatch && teamMatch;
    }).toList()
      ..sort((a, b) {
        final dateComp = b.operatingDate.compareTo(a.operatingDate);
        if (dateComp != 0) return dateComp;
        return a.shiftNumber.compareTo(b.shiftNumber);
      });
  }

  List<AppUser> get employees {
    if (_restrictedTeams != null) {
      return _employees.where((e) {
        return _restrictedTeams!.any((t) =>
            t.toLowerCase() == e.teamName.toLowerCase() ||
            t.toLowerCase() == 'Team ${e.teamNumber}'.toLowerCase());
      }).toList();
    }
    return _employees;
  }

  bool get isLoading => _loading;
  String? get error => _error;

  DateTime? get filterStart => _filterStart;
  DateTime? get filterEnd => _filterEnd;
  String? get filterEmployeeId => _filterEmployeeId;
  int? get filterShift => _filterShift;
  int? get filterTeamNumber => _filterTeamNumber;
  String? get filterTeamName => _filterTeamName;

  List<String> get availableTeamNames {
    if (_restrictedTeams != null) {
      return List.from(_restrictedTeams!)..sort();
    }
    final teams = _reports
        .map((r) => r.teamName.isNotEmpty ? r.teamName : 'Team ${r.teamNumber}')
        .toSet()
        .toList()
      ..sort();
    if (teams.isEmpty) return ['Team 1'];
    return teams;
  }

  List<int> get availableTeams {
    final teams = _reports.map((r) => r.teamNumber).toSet().toList()..sort();
    if (teams.isEmpty) return [1];
    return teams;
  }

  void setFilters({
    DateTime? start,
    DateTime? end,
    String? employeeId,
    int? shift,
    int? teamNumber,
    String? teamName,
  }) {
    _filterStart = start;
    _filterEnd = end;
    _filterEmployeeId = employeeId;
    _filterShift = shift;
    _filterTeamNumber = teamNumber;
    _filterTeamName = teamName;
    notifyListeners();
  }

  void clearFilters() {
    _filterStart = null;
    _filterEnd = null;
    _filterEmployeeId = null;
    _filterShift = null;
    _filterTeamNumber = null;
    _filterTeamName = null;
    notifyListeners();
  }

  Future<void> loadAll() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _reports = await _repo.getAllReports();
      _employees = await _repo.getEmployees();
    } catch (e) {
      _error = 'Failed to load reports: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadForEmployee(String employeeId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _reports = await _repo.getReportsByEmployee(employeeId);
    } catch (e) {
      _error = 'Failed to load reports: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> submitReport(ShiftReport report) async {
    try {
      final isDup = await _repo.isDuplicateReport(
          report.employeeId, report.operatingDate, report.shiftNumber);
      if (isDup) {
        _error = 'A report for this shift and date already exists.';
        notifyListeners();
        return false;
      }
      final saved = await _repo.submitReport(report);
      _reports.add(saved);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to submit report: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateReport(ShiftReport report) async {
    try {
      final updated = await _repo.updateReport(report);
      final idx = _reports.indexWhere((r) => r.id == report.id);
      if (idx >= 0) {
        _reports[idx] = updated;
      } else {
        _reports.add(updated);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update report: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteReport(String reportId) async {
    try {
      await _repo.deleteReport(reportId);
      _reports.removeWhere((r) => r.id == reportId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete report: $e';
      notifyListeners();
      return false;
    }
  }

  /// Bulk-delete a list of report IDs. Returns the count of successfully deleted reports.
  Future<int> deleteReports(List<String> reportIds) async {
    int deleted = 0;
    for (final id in reportIds) {
      try {
        await _repo.deleteReport(id);
        _reports.removeWhere((r) => r.id == id);
        deleted++;
      } catch (_) {}
    }
    notifyListeners();
    return deleted;
  }


  Future<void> updateStatus(
      String reportId, ReportStatus status, String adminName,
      {String? notes}) async {
    try {
      final updated = await _repo.updateReportStatus(
          reportId, status, adminName, notes: notes);
      final idx = _reports.indexWhere((r) => r.id == reportId);
      if (idx >= 0) _reports[idx] = updated;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update status: $e';
      notifyListeners();
    }
  }

  void setTeamFilter(String? teamName) {
    setFilters(
      start: _filterStart,
      end: _filterEnd,
      employeeId: _filterEmployeeId,
      shift: _filterShift,
      teamName: teamName,
    );
  }

  // ── Dashboard Calculations ──────────────────────────────────────
  List<ShiftReport> get todaysReports {
    final today = DateTime.now();
    return _reports.where((r) {
      final isToday = r.operatingDate.year == today.year &&
          r.operatingDate.month == today.month &&
          r.operatingDate.day == today.day;
      if (!isToday) return false;
      if (_filterTeamName != null && _filterTeamName!.isNotEmpty) {
        return r.teamName.toLowerCase() == _filterTeamName!.toLowerCase() ||
            'Team ${r.teamNumber}'.toLowerCase() == _filterTeamName!.toLowerCase();
      }
      if (_filterTeamNumber != null) {
        return r.teamNumber == _filterTeamNumber;
      }
      return true;
    }).toList();
  }

  int get todaysMissingShifts {
    final submitted = todaysReports.map((r) => r.shiftNumber).toSet();
    return 3 - submitted.length;
  }

  double get todaysTotalDepositCommission =>
      todaysReports.fold(0, (s, r) => s + r.depositCommission);

  double get todaysTotalWithdrawalCommission =>
      todaysReports.fold(0, (s, r) => s + r.withdrawalCommission);

  double get todaysTotalCommission =>
      todaysReports.fold(0, (s, r) => s + r.totalCommission);

  double? get todays24HourDeviation {
    final s1 = todaysReports.where((r) => r.shiftNumber == 1).firstOrNull?.deviation;
    final s2 = todaysReports.where((r) => r.shiftNumber == 2).firstOrNull?.deviation;
    final s3 = todaysReports.where((r) => r.shiftNumber == 3).firstOrNull?.deviation;
    return AppUtils.dailyDeviation(s1, s2, s3);
  }

  // ── Date Range Summary ─────────────────────────────────────────
  Map<String, double> getIntervalSummary(List<ShiftReport> reports) {
    final totalDep = reports.fold(0.0, (s, r) => s + r.totalDeposit);
    final totalWd = reports.fold(0.0, (s, r) => s + r.totalWithdrawal);
    final depComm = reports.fold(0.0, (s, r) => s + r.depositCommission);
    final wdComm = reports.fold(0.0, (s, r) => s + r.withdrawalCommission);
    final totComm = reports.fold(0.0, (s, r) => s + r.totalCommission);
    final totalDev = reports.fold(0.0, (s, r) => s + r.deviation);
    return {
      'totalDeposit': totalDep,
      'totalWithdrawal': totalWd,
      'depositCommission': depComm,
      'withdrawalCommission': wdComm,
      'totalCommission': totComm,
      'totalDeviation': totalDev,
    };
  }

  // Overrides for Daily Expected & Actual Amounts
  final Map<String, double> _dailyExpectedOverrides = {};
  final Map<String, double> _dailyActualOverrides = {};

  void setDailyExpectedOverride(DateTime date, double value) {
    final key = AppUtils.formatDateStorage(date);
    _dailyExpectedOverrides[key] = value;
    notifyListeners();
  }

  void setDailyActualOverride(DateTime date, double value) {
    final key = AppUtils.formatDateStorage(date);
    _dailyActualOverrides[key] = value;
    notifyListeners();
  }

  void setDailyOverrides(DateTime date, {double? expected, double? actual}) {
    final key = AppUtils.formatDateStorage(date);
    if (expected != null) _dailyExpectedOverrides[key] = expected;
    if (actual != null) _dailyActualOverrides[key] = actual;
    notifyListeners();
  }

  void clearDailyOverrides(DateTime date) {
    final key = AppUtils.formatDateStorage(date);
    _dailyExpectedOverrides.remove(key);
    _dailyActualOverrides.remove(key);
    notifyListeners();
  }

  List<DailySummary> getDailySummaries(List<ShiftReport> reports) {
    final byDate = <String, List<ShiftReport>>{};
    for (final r in reports) {
      final key = AppUtils.formatDateStorage(r.operatingDate);
      byDate.putIfAbsent(key, () => []).add(r);
    }
    return byDate.entries.map((entry) {
      final dateReports = entry.value;
      final s1 = dateReports.where((r) => r.shiftNumber == 1).firstOrNull;
      final s2 = dateReports.where((r) => r.shiftNumber == 2).firstOrNull;
      final s3 = dateReports.where((r) => r.shiftNumber == 3).firstOrNull;
      final isComplete = s1 != null && s2 != null && s3 != null;

      final totalCommissionAll =
          dateReports.fold(0.0, (s, r) => s + r.totalCommission);
      final totalUnprocessedAll =
          dateReports.fold(0.0, (s, r) => s + r.totalUnprocessed);
      final addedAll = dateReports.fold(0.0, (s, r) => s + r.added);
      final depositComplaintAll =
          dateReports.fold(0.0, (s, r) => s + r.depositComplaintAccepted);
      final takenAll = dateReports.fold(0.0, (s, r) => s + r.taken);

      final calcExpected = AppUtils.expectedAmount(
        initialReddyS1: s1?.initialReddy ?? 0.0,
        initialAccountS1: s1?.initialAccount ?? 0.0,
        endBalanceS2: s2?.endBalance ?? 0.0,
        endBalanceS3: s3?.endBalance ?? 0.0,
        totalCommissionAll: totalCommissionAll,
        totalUnprocessedAll: totalUnprocessedAll,
        addedAll: addedAll,
        depositComplaintAll: depositComplaintAll,
        takenAll: takenAll,
      );

      final calcActual = AppUtils.actualAmount(
        endReddyS3: s3?.endReddy ?? 0.0,
        endBalanceS1: s1?.endBalance ?? 0.0,
        endBalanceS2: s2?.endBalance ?? 0.0,
        endBalanceS3: s3?.endBalance ?? 0.0,
        transferToNextS3: s3?.transferToNext ?? 0.0,
      );

      final hasExpOverride = _dailyExpectedOverrides.containsKey(entry.key);
      final hasActOverride = _dailyActualOverrides.containsKey(entry.key);
      final effExpected = hasExpOverride
          ? _dailyExpectedOverrides[entry.key]!
          : calcExpected;
      final effActual =
          hasActOverride ? _dailyActualOverrides[entry.key]! : calcActual;

      final dailyDeviation = effActual - effExpected;

      return DailySummary(
        date: AppUtils.parseDate(entry.key),
        shift1: s1,
        shift2: s2,
        shift3: s3,
        dailyDeviation: dailyDeviation,
        calculatedExpected: calcExpected,
        calculatedActual: calcActual,
        expectedAmount: effExpected,
        actualAmount: effActual,
        isExpectedOverridden: hasExpOverride,
        isActualOverridden: hasActOverride,
        isComplete: isComplete,
      );
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
}

class DailySummary {
  final DateTime date;
  final ShiftReport? shift1;
  final ShiftReport? shift2;
  final ShiftReport? shift3;
  final double? dailyDeviation;
  final double calculatedExpected;
  final double calculatedActual;
  final double expectedAmount;
  final double actualAmount;
  final bool isExpectedOverridden;
  final bool isActualOverridden;
  final bool isComplete;

  const DailySummary({
    required this.date,
    required this.shift1,
    required this.shift2,
    required this.shift3,
    required this.dailyDeviation,
    required this.calculatedExpected,
    required this.calculatedActual,
    required this.expectedAmount,
    required this.actualAmount,
    required this.isExpectedOverridden,
    required this.isActualOverridden,
    required this.isComplete,
  });
}
