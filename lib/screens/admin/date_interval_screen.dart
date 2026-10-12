import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../providers/report_provider.dart';
import '../../data/models/shift_report_model.dart';

class DateIntervalScreen extends StatefulWidget {
  const DateIntervalScreen({super.key});

  @override
  State<DateIntervalScreen> createState() => _DateIntervalScreenState();
}

class _DateIntervalScreenState extends State<DateIntervalScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  String? _selectedEmployeeId;
  int? _selectedShift;

  List<ShiftReport> _filteredReports = [];
  bool _hasSearched = false;

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (ctx, child) => Theme(data: AppTheme.darkTheme, child: child!),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) _endDate = _startDate;
        } else {
          _endDate = picked;
          if (_startDate.isAfter(_endDate)) _startDate = _endDate;
        }
      });
    }
  }

  void _applyFilter() {
    final rp = context.read<ReportProvider>();
    setState(() {
      _filteredReports = rp.reports.where((r) {
        final inRange = !r.operatingDate
                .isBefore(DateTime(_startDate.year, _startDate.month, _startDate.day)) &&
            !r.operatingDate
                .isAfter(DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59));
        final empMatch =
            _selectedEmployeeId == null || r.employeeId == _selectedEmployeeId;
        final shiftMatch =
            _selectedShift == null || r.shiftNumber == _selectedShift;
        return inRange && empMatch && shiftMatch;
      }).toList()
        ..sort((a, b) {
          final d = b.operatingDate.compareTo(a.operatingDate);
          if (d != 0) return d;
          return a.shiftNumber.compareTo(b.shiftNumber);
        });
      _hasSearched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final rp = context.watch<ReportProvider>();
    final summary = _hasSearched ? rp.getIntervalSummary(_filteredReports) : null;
    final dailySummaries =
        _hasSearched ? rp.getDailySummaries(_filteredReports) : <DailySummary>[];
    final totalDeviation = summary?['totalDeviation'] ?? 0.0;
    final devColor = totalDeviation >= 0
        ? AppTheme.deviationPositive
        : AppTheme.deviationNegative;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Date Interval Report'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Filter Card ────────────────────────────────────
            _buildFilterCard(context, rp),
            const SizedBox(height: 20),

            // ── Results ────────────────────────────────────────
            if (_hasSearched) ...[
              _buildSummaryCard(context, summary!, totalDeviation, devColor),
              const SizedBox(height: 20),

              // Daily Breakdown
              Text('Daily Breakdown',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              ...dailySummaries.map((s) => _buildDayRow(context, s)),
              const SizedBox(height: 20),

              // Reports List
              Text('Reports (${_filteredReports.length})',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              if (_filteredReports.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No reports found for this interval'),
                  ),
                )
              else
                ..._filteredReports.asMap().entries.map(
                      (e) => _buildReportRow(context, e.value, e.key),
                    ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterCard(BuildContext context, ReportProvider rp) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.bgBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_list_rounded,
                  color: AppTheme.accent, size: 20),
              const SizedBox(width: 8),
              Text('Filters',
                  style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 16),

          // Date selectors
          Row(
            children: [
              Expanded(child: _datePicker('Start Date', _startDate, true)),
              const SizedBox(width: 12),
              Expanded(child: _datePicker('End Date', _endDate, false)),
            ],
          ),
          const SizedBox(height: 12),

          // Employee & Shift filters
          Row(
            children: [
              Expanded(
                child: _dropdownField(
                  value: _selectedEmployeeId,
                  hint: 'All Employees',
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Employees')),
                    ...rp.employees.map((e) => DropdownMenuItem(
                          value: e.id,
                          child: Text(e.name, overflow: TextOverflow.ellipsis),
                        )),
                  ],
                  onChanged: (v) => setState(() => _selectedEmployeeId = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _dropdownField<int>(
                  value: _selectedShift,
                  hint: 'All Shifts',
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Shifts')),
                    ...List.generate(3, (i) => DropdownMenuItem(
                          value: i + 1,
                          child: Text('Shift ${i + 1}'),
                        )),
                  ],
                  onChanged: (v) => setState(() => _selectedShift = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _applyFilter,
              icon: const Icon(Icons.search_rounded, size: 18),
              label: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _datePicker(String label, DateTime date, bool isStart) {
    return GestureDetector(
      onTap: () => _pickDate(isStart: isStart),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.bgBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 14, color: AppTheme.textMuted),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 10)),
                Text(AppUtils.formatDate(date),
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdownField<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.bgBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint,
              style: const TextStyle(
                  color: AppTheme.textMuted, fontSize: 12)),
          dropdownColor: AppTheme.bgCard,
          style: const TextStyle(
              color: AppTheme.textPrimary, fontSize: 12),
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, Map<String, double> summary,
      double totalDev, Color devColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.bgBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.summarize_rounded,
                  color: AppTheme.accent, size: 20),
              const SizedBox(width: 8),
              Text('Interval Summary',
                  style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${AppUtils.formatDate(_startDate)} → ${AppUtils.formatDate(_endDate)}',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          _summaryRow(context, 'Reports Count', '${_filteredReports.length}',
              icon: Icons.description_outlined),
          _summaryRow(context, 'Total Deposit',
              AppUtils.formatCurrency(summary['totalDeposit']!)),
          _summaryRow(context, 'Total Withdrawal',
              AppUtils.formatCurrency(summary['totalWithdrawal']!)),
          const Divider(),
          _summaryRow(context, 'Deposit Commission (3%)',
              AppUtils.formatCurrency(summary['depositCommission']!),
              color: AppTheme.success),
          _summaryRow(context, 'Withdrawal Commission (2%)',
              AppUtils.formatCurrency(summary['withdrawalCommission']!),
              color: AppTheme.success),
          _summaryRow(context, 'Total Commission',
              AppUtils.formatCurrency(summary['totalCommission']!),
              color: AppTheme.accent,
              bold: true),
          const Divider(),
          _summaryRow(
            context,
            'Total Deviation',
            AppUtils.formatDeviation(totalDev),
            color: devColor,
            bold: true,
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _summaryRow(BuildContext context, String label, String value,
      {Color? color, bool bold = false, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: AppTheme.textMuted),
            const SizedBox(width: 6),
          ],
          Expanded(
              child: Text(label,
                  style: Theme.of(context).textTheme.bodyMedium)),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color ?? AppTheme.textPrimary,
                  fontWeight:
                      bold ? FontWeight.w700 : FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayRow(BuildContext context, DailySummary s) {
    final devColor = s.dailyDeviation == null
        ? AppTheme.textMuted
        : s.dailyDeviation! >= 0
            ? AppTheme.deviationPositive
            : AppTheme.deviationNegative;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: s.isComplete ? AppTheme.bgBorder : AppTheme.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Text(AppUtils.formatDate(s.date),
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(width: 8),
          _shiftDot(1, s.shift1 != null),
          _shiftDot(2, s.shift2 != null),
          _shiftDot(3, s.shift3 != null),
          const Spacer(),
          if (!s.isComplete)
            const Text('Incomplete',
                style: TextStyle(color: AppTheme.error, fontSize: 11))
          else
            Text(
              AppUtils.formatDeviation(s.dailyDeviation!),
              style: TextStyle(
                  color: devColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14),
            ),
        ],
      ),
    );
  }

  Widget _shiftDot(int num, bool present) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: present
            ? AppTheme.success.withOpacity(0.2)
            : AppTheme.error.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: present
                ? AppTheme.success.withOpacity(0.4)
                : AppTheme.error.withOpacity(0.3)),
      ),
      child: Text(
        'S$num',
        style: TextStyle(
          color: present ? AppTheme.success : AppTheme.error,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildReportRow(BuildContext context, ShiftReport r, int i) {
    final devColor = r.deviation >= 0
        ? AppTheme.deviationPositive
        : AppTheme.deviationNegative;

    return GestureDetector(
      onTap: () => context.push('/admin/report/${r.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.bgBorder),
        ),
        child: Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('S${r.shiftNumber}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppUtils.formatDate(r.operatingDate),
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  Text(r.employeeName,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(AppUtils.formatCurrency(r.totalCommission),
                    style: const TextStyle(
                        color: AppTheme.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
                Text(
                  AppUtils.formatDeviation(r.deviation),
                  style: TextStyle(
                      color: devColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right,
                color: AppTheme.textMuted, size: 18),
          ],
        ),
      ).animate(delay: Duration(milliseconds: i * 30)).fadeIn(),
    );
  }
}
