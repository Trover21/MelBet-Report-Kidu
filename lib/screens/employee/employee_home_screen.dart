import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';
import '../../data/models/shift_report_model.dart';
import '../admin/widgets/status_badge.dart';

class EmployeeHomeScreen extends StatefulWidget {
  const EmployeeHomeScreen({super.key});

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.user != null) {
        context.read<ReportProvider>().loadForEmployee(auth.user!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final reports = context.watch<ReportProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // ── AppBar ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.bar_chart_rounded,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back,',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              auth.user?.name ?? 'Employee',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: AppTheme.textSecondary),
                        onPressed: () {
                          auth.logout();
                          context.go('/login');
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // ── Submit Report Button ────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: _buildSubmitCard(context),
                ),
              ),

              // ── Stats ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _buildStatsRow(context, reports.reports),
                ),
              ),

              // ── Report List ────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                sliver: reports.isLoading
                    ? const SliverToBoxAdapter(
                        child: Center(
                            child: CircularProgressIndicator(
                                color: AppTheme.primary)),
                      )
                    : reports.reports.isEmpty
                        ? SliverToBoxAdapter(child: _buildEmptyState())
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) {
                                final sorted = [...reports.reports]
                                  ..sort((a, b) => b.operatingDate
                                      .compareTo(a.operatingDate));
                                return _buildReportCard(context, sorted[i], i);
                              },
                              childCount: reports.reports.length,
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/employee/submit-report'),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add),
        label: const Text('New Report'),
      ),
    );
  }

  Widget _buildSubmitCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.assignment_add, color: Colors.white, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Submit Shift Report',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  'Record your shift figures',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => context.push('/employee/submit-report'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Start'),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildStatsRow(BuildContext context, List<ShiftReport> reports) {
    final total = reports.length;
    final totalDev = reports.fold(0.0, (s, r) => s + r.deviation);
    final totalComm = reports.fold(0.0, (s, r) => s + r.totalCommission);

    return Row(
      children: [
        _statCard(context, 'Total Reports', '$total', Icons.description_outlined),
        const SizedBox(width: 12),
        _statCard(context, 'Total Commission',
            AppUtils.formatCurrency(totalComm), Icons.percent_rounded,
            color: AppTheme.success),
        const SizedBox(width: 12),
        _statCard(
          context,
          'Net Deviation',
          AppUtils.formatDeviation(totalDev),
          Icons.trending_up_rounded,
          color: totalDev >= 0 ? AppTheme.deviationPositive : AppTheme.deviationNegative,
        ),
      ],
    );
  }

  Widget _statCard(BuildContext context, String label, String value,
      IconData icon,
      {Color color = AppTheme.primary}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.bgBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ).animate().fadeIn(delay: 200.ms),
    );
  }

  Widget _buildReportCard(BuildContext context, ShiftReport report, int index) {
    final devColor = report.deviation > 0
        ? AppTheme.deviationPositive
        : report.deviation < 0
            ? AppTheme.deviationNegative
            : AppTheme.deviationZero;

    return GestureDetector(
      onTap: () => context.push('/employee/report/${report.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.bgBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      report.shiftLabel,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppUtils.formatDate(report.operatingDate),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  StatusBadge(status: report.status),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  _infoItem(context, 'Deposit',
                      AppUtils.formatCurrency(report.totalDeposit)),
                  _infoItem(context, 'Withdrawal',
                      AppUtils.formatCurrency(report.totalWithdrawal)),
                  _infoItem(context, 'Commission',
                      AppUtils.formatCurrency(report.totalCommission),
                      color: AppTheme.success),
                  _infoItem(context, 'Deviation',
                      AppUtils.formatDeviation(report.deviation),
                      color: devColor),
                ],
              ),
              if (report.status == ReportStatus.correctionRequested) ...[
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: AppTheme.warning.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.edit_note,
                          size: 16, color: AppTheme.warning),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          report.notes != null && report.notes!.isNotEmpty
                              ? 'Admin: "${report.notes}" — Tap to edit & resubmit'
                              : 'Correction requested by admin — Tap to edit & resubmit',
                          style: const TextStyle(
                            color: AppTheme.warning,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          size: 16, color: AppTheme.warning),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ).animate(delay: Duration(milliseconds: index * 60)).fadeIn().slideY(begin: 0.1, end: 0),
    );
  }

  Widget _infoItem(BuildContext context, String label, String value,
      {Color? color}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color ?? AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            const Icon(Icons.inbox_rounded,
                size: 72, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            Text('No reports yet',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Submit your first shift report using the button below.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
