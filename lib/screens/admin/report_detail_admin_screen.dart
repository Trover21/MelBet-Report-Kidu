import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';
import '../../data/models/shift_report_model.dart';
import 'widgets/status_badge.dart';
import '../../widgets/super_manager_report_card.dart';

class ReportDetailAdminScreen extends StatelessWidget {
  final String reportId;
  const ReportDetailAdminScreen({super.key, required this.reportId});

  @override
  Widget build(BuildContext context) {
    final reports = context.watch<ReportProvider>().reports;
    final report = reports.where((r) => r.id == reportId).firstOrNull;
    final auth = context.read<AuthProvider>();

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
        actions: [
          StatusBadge(status: report.status),
          const SizedBox(width: 12),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Employee Info ──────────────────────────────────
            _employeeCard(context, report),
            const SizedBox(height: 16),

            // ── Super Manager Format Card ─────────────────────
            SuperManagerReportCard.fromReport(report),
            const SizedBox(height: 16),

            // ── Deviation Hero ─────────────────────────────────
            _deviationHero(context, report, devColor),
            const SizedBox(height: 16),

            // ── Commission Summary ────────────────────────────
            _commissionCard(context, report),
            const SizedBox(height: 16),

            // ── All Fields ────────────────────────────────────
            _section(context, 'Opening Balances', [
              _row(context, 'Initial Reddy', report.initialReddy),
              _row(context, 'Initial Account', report.initialAccount),
            ]),
            const SizedBox(height: 12),
            _section(context, 'Transactions', [
              _row(context, 'Total Deposit', report.totalDeposit),
              _row(context, 'Total Withdrawal', report.totalWithdrawal),
            ]),
            const SizedBox(height: 12),
            _section(context, 'Closing', [
              _row(context, 'End Reddy', report.endReddy),
              _row(context, 'Transfer to Next', report.transferToNext),
              _row(context, 'End Balance', report.endBalance,
                  color: AppTheme.accent),
            ]),
            const SizedBox(height: 12),
            _section(context, 'Complaints & Adjustments', [
              _row(context, 'Deposit Complaint', report.depositComplaintAccepted),
              _row(context, 'Withdrawal Complaint', report.withdrawalComplaintAccepted),
              _row(context, 'Prev-Day Pending Deposit', report.prevDayPendingDepositApproved),
              _row(context, 'Deposit OK After Shift', report.depositOkAfterShift),
              _row(context, 'Withdrawal OK After Shift', report.withdrawalOkAfterShift),
              _row(context, 'Deposit OK Before Shift', report.depositOkBeforeShift),
              _row(context, 'Withdrawal Before Shift', report.withdrawalApprovedBeforeShift),
              _row(context, 'Total Unprocessed', report.totalUnprocessed),
              _row(context, 'Added', report.added),
              _row(context, 'Taken', report.taken),
            ]),
            const SizedBox(height: 12),
            _section(context, 'Calculated Results', [
              _row(context, 'Expected Amount', report.expectedAmount),
              _row(context, 'Actual Amount', report.actualAmount),
              _rowDev(context, 'Deviation', report.deviation, devColor),
            ]),
            const SizedBox(height: 16),

            // ── Correction Notes (if any) ─────────────────────
            if (report.notes != null && report.notes!.isNotEmpty) ...[
              _correctionNoteCard(context, report),
              const SizedBox(height: 16),
            ],

            // ── Admin Actions ──────────────────────────────────
            _adminActions(context, report, auth.user?.name ?? 'Admin'),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _employeeCard(BuildContext context, ShiftReport r) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.bgBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.primary.withOpacity(0.2),
            child: Text(
              r.employeeName.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                  color: AppTheme.primary, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(r.employeeName,
                  style: Theme.of(context).textTheme.titleSmall),
              Text('Submitted: ${AppUtils.formatDateTime(r.submittedAt)}',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _deviationHero(BuildContext context, ShiftReport r, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), AppTheme.bgCard],
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
                const SizedBox(height: 4),
                Text(
                  '= Actual (${AppUtils.formatCurrency(r.actualAmount)}) '
                  '− Expected (${AppUtils.formatCurrency(r.expectedAmount)})',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppTheme.textMuted),
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
    );
  }

  Widget _commissionCard(BuildContext context, ShiftReport r) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.bgBorder),
      ),
      child: Row(
        children: [
          _ci(context, 'Deposit\nComm (3%)',
              AppUtils.formatCurrency(r.depositCommission)),
          _vd(),
          _ci(context, 'Withdrawal\nComm (2%)',
              AppUtils.formatCurrency(r.withdrawalCommission)),
          _vd(),
          _ci(context, 'Total\nCommission',
              AppUtils.formatCurrency(r.totalCommission),
              highlight: true),
        ],
      ),
    );
  }

  Widget _ci(BuildContext context, String label, String value,
      {bool highlight = false}) =>
      Expanded(
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: highlight ? AppTheme.accent : AppTheme.success,
                fontWeight: FontWeight.w700,
                fontSize: 14,
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

  Widget _vd() => const VerticalDivider(
      width: 1, color: AppTheme.bgBorder, indent: 4, endIndent: 4);

  Widget _section(BuildContext context, String title, List<Widget> rows) {
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
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          ...rows,
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, double value,
      {Color? color}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
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

  Widget _rowDev(BuildContext context, String l, double v, Color color) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l, style: Theme.of(context).textTheme.bodyMedium),
            Text(
              AppUtils.formatDeviation(v),
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
      );

  Widget _correctionNoteCard(BuildContext context, ShiftReport report) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warning.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warning.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppTheme.warning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Correction Request Notes',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.warning,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            report.notes!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
          ),
        ],
      ),
    );
  }

  Widget _adminActions(
      BuildContext context, ShiftReport report, String adminName) {
    final rp = context.read<ReportProvider>();
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
          Text('Admin Actions',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (report.status != ReportStatus.approved)
                ElevatedButton.icon(
                  onPressed: () async {
                    await rp.updateStatus(
                        report.id, ReportStatus.approved, adminName);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Report approved'),
                            backgroundColor: AppTheme.success),
                      );
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success),
                ),
              if (report.status != ReportStatus.reviewed)
                OutlinedButton.icon(
                  onPressed: () async {
                    await rp.updateStatus(
                        report.id, ReportStatus.reviewed, adminName);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Marked as reviewed')),
                      );
                    }
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('Mark Reviewed'),
                ),
              OutlinedButton.icon(
                onPressed: () async {
                  final notesCtrl =
                      TextEditingController(text: report.notes ?? '');
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Request Correction'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Provide instructions for ${report.employeeName} on what needs to be corrected:',
                            style: Theme.of(ctx).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: notesCtrl,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              hintText:
                                  'e.g., Initial Reddy balance does not match handover.',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.warning),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Send Request'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    await rp.updateStatus(
                      report.id,
                      ReportStatus.correctionRequested,
                      adminName,
                      notes: notesCtrl.text.trim().isNotEmpty
                          ? notesCtrl.text.trim()
                          : 'Please review and correct figures before resubmission.',
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Correction requested. Employee can now edit and resend.'),
                          backgroundColor: AppTheme.warning,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Request Correction'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.warning,
                    side: const BorderSide(color: AppTheme.warning)),
              ),
              // ── Remove Report Button ───────────────────────────
              OutlinedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Remove Report'),
                      content: Text(
                        'Are you sure you want to delete this report from ${report.employeeName} (${report.shiftLabel})?\n\nThis action cannot be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.error),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Delete Report'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    final ok = await rp.deleteReport(report.id);
                    if (context.mounted && ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Report removed successfully'),
                          backgroundColor: AppTheme.error,
                        ),
                      );
                      context.pop();
                    }
                  }
                },
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Remove Report'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.error,
                  side: const BorderSide(color: AppTheme.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

