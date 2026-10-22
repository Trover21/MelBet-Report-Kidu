import 'package:flutter/material.dart';
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
            _sectionCard(context, 'Submission Info', [
              _rowText(context, 'Submitted By', report.employeeName),
              _rowText(context, 'Team', report.teamName),
              if (report.shiftStartTime.isNotEmpty && report.shiftEndTime.isNotEmpty)
                _rowText(context, 'Shift Time', '${report.shiftStartTime} – ${report.shiftEndTime}'),
              _rowText(context, 'Submitted At', AppUtils.formatDateTime(report.submittedAt)),
              _rowText(context, 'Status', report.status.label),
              if (report.notes != null && report.notes!.isNotEmpty)
                _rowText(context, 'Notes', report.notes!),
            ]),
            const SizedBox(height: 16),

            // ── End Balance at Bottom of Report ────────────────
            _buildEndBalanceCard(context, report),
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

  Widget _buildEndBalanceCard(BuildContext context, ShiftReport report) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accent.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppTheme.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'End Balance',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Closing calculated balance',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Text(
            AppUtils.formatCurrency(report.endBalance),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.accent,
            ),
          ),
        ],
      ),
    );
  }

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
