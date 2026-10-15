import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../providers/report_provider.dart';
import '../../data/models/shift_report_model.dart';
import '../admin/widgets/status_badge.dart';

class ReportDetailScreen extends StatelessWidget {
  final String reportId;
  const ReportDetailScreen({super.key, required this.reportId});

  @override
  Widget build(BuildContext context) {
    final reports = context.watch<ReportProvider>().reports;
    final report = reports.where((r) => r.id == reportId).firstOrNull;

    if (report == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Report Detail')),
        body: const Center(child: Text('Report not found')),
      );
    }

    final devColor = report.deviation > 0
        ? AppTheme.deviationPositive
        : report.deviation < 0
            ? AppTheme.deviationNegative
            : AppTheme.deviationZero;

    return Scaffold(
      appBar: AppBar(
        title: Text('${report.shiftLabel} — ${AppUtils.formatDate(report.operatingDate)}'),
        leading: BackButton(onPressed: () => context.pop()),
        actions: [StatusBadge(status: report.status)],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Correction Requested Alert (if applicable) ────
            if (report.status == ReportStatus.correctionRequested) ...[
              _correctionRequestedBanner(context, report),
              const SizedBox(height: 16),
            ],

            // ── Deviation Hero ─────────────────────────────────
            _deviationHero(context, report, devColor),
            const SizedBox(height: 20),

            // ── Commission Summary ────────────────────────────
            _commissionCard(context, report),
            const SizedBox(height: 20),

            // ── Input Fields ──────────────────────────────────
            _sectionCard(context, 'Opening Balances', [
              _row(context, 'Initial Reddy', report.initialReddy),
              _row(context, 'Initial Account', report.initialAccount),
            ]),
            const SizedBox(height: 12),
            _sectionCard(context, 'Transactions', [
              _row(context, 'Total Deposit', report.totalDeposit),
              _row(context, 'Total Withdrawal', report.totalWithdrawal),
            ]),
            const SizedBox(height: 12),
            _sectionCard(context, 'Closing', [
              _row(context, 'End Reddy', report.endReddy),
              _row(context, 'Transfer to Next', report.transferToNext),
              _row(context, 'End Balance', report.endBalance,
                  color: AppTheme.accent),
            ]),
            const SizedBox(height: 12),
            _sectionCard(context, 'Complaints & Adjustments', [
              _row(context, 'Deposit Complaint', report.depositComplaintAccepted),
              _row(context, 'Withdrawal Complaint', report.withdrawalComplaintAccepted),
              _row(context, 'Total Unprocessed', report.totalUnprocessed),
              _row(context, 'Added', report.added),
              _row(context, 'Taken', report.taken),
            ]),
            const SizedBox(height: 12),
            _sectionCard(context, 'Calculated Results', [
              _row(context, 'Expected Amount', report.expectedAmount),
              _row(context, 'Actual Amount', report.actualAmount),
              _rowDev(context, 'Deviation', report.deviation, devColor),
            ]),
            const SizedBox(height: 12),
            _sectionCard(context, 'Submission Info', [
              _rowText(context, 'Submitted By', report.employeeName),
              _rowText(context, 'Submitted At', AppUtils.formatDateTime(report.submittedAt)),
              _rowText(context, 'Status', report.status.label),
              if (report.notes != null && report.notes!.isNotEmpty)
                _rowText(context, 'Notes', report.notes!),
            ]),
            const SizedBox(height: 24),

            if (report.status == ReportStatus.correctionRequested) ...[
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      context.push('/employee/report/${report.id}/edit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.warning,
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.edit_note, size: 20),
                  label: const Text(
                    'Edit & Resubmit Report',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _deviationHero(BuildContext context, ShiftReport r, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.2), AppTheme.bgCard],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Shift Deviation',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 6),
                Text(
                  AppUtils.formatDeviation(r.deviation),
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          Icon(
            r.deviation > 0
                ? Icons.trending_up_rounded
                : r.deviation < 0
                    ? Icons.trending_down_rounded
                    : Icons.trending_flat_rounded,
            color: color,
            size: 56,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _commissionCard(BuildContext context, ShiftReport r) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.bgBorder),
      ),
      child: Row(
        children: [
          _commItem(context, 'Deposit\nComm (3%)',
              AppUtils.formatCurrency(r.depositCommission)),
          _divider(),
          _commItem(context, 'Withdrawal\nComm (2%)',
              AppUtils.formatCurrency(r.withdrawalCommission)),
          _divider(),
          _commItem(context, 'Total\nCommission',
              AppUtils.formatCurrency(r.totalCommission),
              highlight: true),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _commItem(BuildContext context, String label, String value,
      {bool highlight = false}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: highlight ? AppTheme.accent : AppTheme.success,
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _divider() => const VerticalDivider(
        width: 1,
        color: AppTheme.bgBorder,
        indent: 8,
        endIndent: 8,
      );

  Widget _sectionCard(
      BuildContext context, String title, List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.bgBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: AppTheme.textSecondary)),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, double value,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            AppUtils.formatCurrency(value),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color ?? AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _rowDev(
      BuildContext context, String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            AppUtils.formatDeviation(value),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
          ),
        ],
      ),
    );
  }

  Widget _rowText(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _correctionRequestedBanner(BuildContext context, ShiftReport report) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.warning.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warning.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_note_rounded,
                  color: AppTheme.warning, size: 24),
              const SizedBox(width: 8),
              Text(
                'Admin Requested Correction',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.warning,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          if (report.notes != null && report.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Admin Instructions: "${report.notes}"',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () =>
                  context.push('/employee/report/${report.id}/edit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warning,
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.edit, size: 16),
              label: const Text(
                'Edit & Resubmit Now',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
