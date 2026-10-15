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

  ReportProvider(this._repo);

  List<ShiftReport> get reports => _reports;
  List<ShiftReport> get filteredReports {
    return _reports.where((r) {
      final inRange = (_filterStart == null ||
              !r.operatingDate.isBefore(_filterStart!)) &&
          (_filterEnd == null || !r.operatingDate.isAfter(_filterEnd!));
      final empMatch = _filterEmployeeId == null || _filterEmployeeId!.isEmpty ||
          r.employeeId == _filterEmployeeId;
      final shiftMatch =
          _filterShift == null || r.shiftNumber == _filterShift;
      return inRange && empMatch && shiftMatch;
    }).toList()
      ..sort((a, b) {
        final dateComp = b.operatingDate.compareTo(a.operatingDate);
        if (dateComp != 0) return dateComp;
        return a.shiftNumber.compareTo(b.shiftNumber);
      });
  }

  List<AppUser> get employees => _employees;
  bool get isLoading => _loading;
  String? get error => _error;

  DateTime? get filterStart => _filterStart;
  DateTime? get filterEnd => _filterEnd;
  String? get filterEmployeeId => _filterEmployeeId;
  int? get filterShift => _filterShift;

  void setFilters({
    DateTime? start,
    DateTime? end,
    String? employeeId,
    int? shift,
  }) {
    _filterStart = start;
    _filterEnd = end;
    _filterEmployeeId = employeeId;
    _filterShift = shift;
    notifyListeners();
  }

  void clearFilters() {
    _filterStart = null;
    _filterEnd = null;
    _filterEmployeeId = null;
    _filterShift = null;
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

  // ── Dashboard Calculations ──────────────────────────────────────
  List<ShiftReport> get todaysReports {
    final today = DateTime.now();
    return _reports.where((r) =>
        r.operatingDate.year == today.year &&
        r.operatingDate.month == today.month &&
        r.operatingDate.day == today.day).toList();
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
      final daily = AppUtils.dailyDeviation(
          s1?.deviation, s2?.deviation, s3?.deviation);
      return DailySummary(
        date: AppUtils.parseDate(entry.key),
        shift1: s1,
        shift2: s2,
        shift3: s3,
        dailyDeviation: daily,
        isComplete: s1 != null && s2 != null && s3 != null,
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
  final bool isComplete;

  const DailySummary({
    required this.date,
    required this.shift1,
    required this.shift2,
    required this.shift3,
    required this.dailyDeviation,
    required this.isComplete,
  });
}
