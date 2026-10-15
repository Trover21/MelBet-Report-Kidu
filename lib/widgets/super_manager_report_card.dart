import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_utils.dart';
import '../data/models/shift_report_model.dart';

/// Reusable card displaying the exact format required by Super Managers:
/// - Date
/// - Initial Ready
/// - Initial Account
/// - Deposit Commi
/// - With Commi
/// - Total Commi
/// - End Ready
/// - End Account
/// - Expected = Initial Ready + Initial Account + Total Commi
/// - Actual = End Ready + End Account
/// - Dev = Actual - Expected
class SuperManagerReportCard extends StatelessWidget {
  final String title;
  final DateTime date;
  final String? employeeName;
  final double initialReddy;
  final double initialAccount;
  final double depositCommission;
  final double withdrawalCommission;
  final double totalCommission;
  final double endReddy;
  final double endAccount;
  final double expected;
  final double actual;
  final double deviation;
  final ReportStatus? status;

  const SuperManagerReportCard({
    super.key,
    required this.title,
    required this.date,
    this.employeeName,
    required this.initialReddy,
    required this.initialAccount,
    required this.depositCommission,
    required this.withdrawalCommission,
    required this.totalCommission,
    required this.endReddy,
    required this.endAccount,
    required this.expected,
    required this.actual,
    required this.deviation,
    this.status,
  });

  factory SuperManagerReportCard.fromReport(ShiftReport report, {String? customTitle}) {
    final endAcc = report.endBalance + report.transferToNext;
    final exp = report.initialReddy + report.initialAccount + report.totalCommission;
    final act = report.endReddy + endAcc;
    final dev = act - exp;

    return SuperManagerReportCard(
      title: customTitle ?? report.shiftLabel,
      date: report.operatingDate,
      employeeName: report.employeeName,
      initialReddy: report.initialReddy,
      initialAccount: report.initialAccount,
      depositCommission: report.depositCommission,
      withdrawalCommission: report.withdrawalCommission,
      totalCommission: report.totalCommission,
      endReddy: report.endReddy,
      endAccount: endAcc,
      expected: exp,
      actual: act,
      deviation: dev,
      status: report.status,
    );
  }

  String generateReportText() {
    final devStr = deviation >= 0
        ? '+${AppUtils.formatCurrency(deviation)}'
        : AppUtils.formatCurrency(deviation);

    final buffer = StringBuffer();
    buffer.writeln('📋 MELBET SHIFT REPORT (SUPER MANAGER FORMAT)');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📅 Date:            ${AppUtils.formatDate(date)}');
    buffer.writeln('🔖 Shift:           $title');
    if (employeeName != null && employeeName!.isNotEmpty) {
      buffer.writeln('👤 Employee:        $employeeName');
    }
    buffer.writeln('────────────────────────────────────────');
    buffer.writeln('💵 Initial Ready:   ${AppUtils.formatCurrency(initialReddy)}');
    buffer.writeln('💳 Initial Account: ${AppUtils.formatCurrency(initialAccount)}');
    buffer.writeln('📥 Deposit Commi:   ${AppUtils.formatCurrency(depositCommission)}');
    buffer.writeln('📤 With Commi:      ${AppUtils.formatCurrency(withdrawalCommission)}');
    buffer.writeln('💰 Total Commi:     ${AppUtils.formatCurrency(totalCommission)}');
    buffer.writeln('🏁 End Ready:       ${AppUtils.formatCurrency(endReddy)}');
    buffer.writeln('🏦 End Account:     ${AppUtils.formatCurrency(endAccount)}');
    buffer.writeln('────────────────────────────────────────');
    buffer.writeln('🎯 Expected:        ${AppUtils.formatCurrency(expected)}');
    buffer.writeln('   (Initial Ready + Initial Account + Total Commi)');
    buffer.writeln('⚖️ Actual:          ${AppUtils.formatCurrency(actual)}');
    buffer.writeln('   (End Ready + End Account)');
    buffer.writeln('📊 Dev:             $devStr');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    return buffer.toString();
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: generateReportText()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Report copied in Super Manager format for $title!',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final devColor = deviation > 0
        ? AppTheme.deviationPositive
        : deviation < 0
            ? AppTheme.deviationNegative
            : AppTheme.deviationZero;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.bgBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.bgSurface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: const Border(bottom: BorderSide(color: AppTheme.bgBorder)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppUtils.formatDate(date),
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      if (employeeName != null && employeeName!.isNotEmpty)
                        Text(
                          employeeName!,
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, color: AppTheme.accent, size: 20),
                  tooltip: 'Copy Super Manager Format',
                  onPressed: () => _copyToClipboard(context),
                ),
              ],
            ),
          ),

          // ── Data Fields Table ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _dataRow('Date', AppUtils.formatDate(date), isDate: true),
                const Divider(height: 12),
                _dataRow('Initial Ready', AppUtils.formatCurrency(initialReddy)),
                _dataRow('Initial Account', AppUtils.formatCurrency(initialAccount)),
                const Divider(height: 12),
                _dataRow('Deposit Commi', AppUtils.formatCurrency(depositCommission), color: AppTheme.success),
                _dataRow('With Commi', AppUtils.formatCurrency(withdrawalCommission), color: AppTheme.warning),
                _dataRow('Total Commi', AppUtils.formatCurrency(totalCommission), color: AppTheme.accent, isBold: true),
                const Divider(height: 12),
                _dataRow('End Ready', AppUtils.formatCurrency(endReddy)),
                _dataRow('End Account', AppUtils.formatCurrency(endAccount)),
                const SizedBox(height: 8),

                // ── Summary Box (Expected, Actual, Dev) ────────────
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.bgBorder),
                  ),
                  child: Column(
                    children: [
                      _calcRow(
                        'Expected',
                        AppUtils.formatCurrency(expected),
                        sub: 'Initial Ready + Initial Account + Total Commi',
                        valueColor: AppTheme.textPrimary,
                      ),
                      const SizedBox(height: 8),
                      _calcRow(
                        'Actual',
                        AppUtils.formatCurrency(actual),
                        sub: 'End Ready + End Account',
                        valueColor: AppTheme.textPrimary,
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dev',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                'Actual − Expected',
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: devColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: devColor.withOpacity(0.4)),
                            ),
                            child: Text(
                              AppUtils.formatDeviation(deviation),
                              style: TextStyle(
                                color: devColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Copy Button ────────────────────────────────────
                OutlinedButton.icon(
                  onPressed: () => _copyToClipboard(context),
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Copy for Super Manager'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accent,
                    side: const BorderSide(color: AppTheme.accent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    minimumSize: const Size(double.infinity, 38),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dataRow(String label, String value, {Color? color, bool isBold = false, bool isDate = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isBold ? AppTheme.textPrimary : AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color ?? (isBold ? AppTheme.textPrimary : AppTheme.textPrimary),
              fontSize: isBold ? 13 : 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _calcRow(String label, String value, {required String sub, required Color valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            Text(
              sub,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 9,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
