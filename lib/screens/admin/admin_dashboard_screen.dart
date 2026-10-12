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

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final reports = context.watch<ReportProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top Bar ────────────────────────────────────────
              _buildTopBar(context, auth),
              const SizedBox(height: 8),

              // ── Tab Bar ────────────────────────────────────────
              _buildTabBar(),

              // ── Tab Views ──────────────────────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(context, reports),
                    _buildReportsTab(context, reports),
                    _buildDailyTab(context, reports),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, AuthProvider auth) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.bar_chart_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Admin Dashboard',
                  style: Theme.of(context).textTheme.titleLarge),
              Text(AppUtils.formatDate(DateTime.now()),
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const Spacer(),
          IconButton(
            icon:
                const Icon(Icons.date_range_rounded, color: AppTheme.accent),
            onPressed: () => context.push('/admin/date-interval'),
            tooltip: 'Date Interval Report',
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
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.bgBorder),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Reports'),
          Tab(text: 'Daily'),
        ],
      ),
    );
  }

  // ── Overview Tab ─────────────────────────────────────────────────
  Widget _buildOverviewTab(BuildContext context, ReportProvider rp) {
    if (rp.isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary));
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Summary cards grid
        _buildSummaryCards(context, rp),
        const SizedBox(height: 20),

        // Today's shift status
        _buildTodaysShiftStatus(context, rp),
        const SizedBox(height: 20),

        // Quick access to interval report
        _buildIntervalCTA(context),
      ],
    );
  }

  Widget _buildSummaryCards(BuildContext context, ReportProvider rp) {
    final devColor = rp.todays24HourDeviation == null
        ? AppTheme.textMuted
        : rp.todays24HourDeviation! > 0
            ? AppTheme.deviationPositive
            : rp.todays24HourDeviation! < 0
                ? AppTheme.deviationNegative
                : AppTheme.deviationZero;

    final cards = [
      _SummaryCardData(
        label: "Today's Reports",
        value: '${rp.todaysReports.length}/3',
        icon: Icons.description_outlined,
        color: AppTheme.primary,
      ),
      _SummaryCardData(
        label: 'Missing Shifts',
        value: '${rp.todaysMissingShifts}',
        icon: Icons.warning_amber_rounded,
        color: rp.todaysMissingShifts > 0 ? AppTheme.error : AppTheme.success,
      ),
      _SummaryCardData(
        label: 'Deposit Comm.',
        value: AppUtils.formatCurrency(rp.todaysTotalDepositCommission),
        icon: Icons.arrow_downward_rounded,
        color: AppTheme.success,
      ),
      _SummaryCardData(
        label: 'Withdrawal Comm.',
        value: AppUtils.formatCurrency(rp.todaysTotalWithdrawalCommission),
        icon: Icons.arrow_upward_rounded,
        color: AppTheme.warning,
      ),
      _SummaryCardData(
        label: 'Total Commission',
        value: AppUtils.formatCurrency(rp.todaysTotalCommission),
        icon: Icons.monetization_on_outlined,
        color: AppTheme.accent,
      ),
      _SummaryCardData(
        label: '24H Deviation',
        value: rp.todays24HourDeviation == null
            ? 'Incomplete'
            : AppUtils.formatDeviation(rp.todays24HourDeviation!),
        icon: Icons.balance_rounded,
        color: devColor,
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: cards.asMap().entries.map((entry) {
        final i = entry.key;
        final card = entry.value;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.bgBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(card.icon, color: card.color, size: 22),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: card.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: card.color,
                          fontWeight: FontWeight.w700,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(card.label,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),
        ).animate(delay: Duration(milliseconds: i * 80)).fadeIn().scale(
            begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
      }).toList(),
    );
  }

  Widget _buildTodaysShiftStatus(BuildContext context, ReportProvider rp) {
    final todayReports = rp.todaysReports;

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
              const Icon(Icons.today_rounded,
                  color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                "Today's Shifts — ${AppUtils.formatDate(DateTime.now())}",
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(3, (i) {
              final shift = i + 1;
              final rep = todayReports
                  .where((r) => r.shiftNumber == shift)
                  .firstOrNull;
              final hasReport = rep != null;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: hasReport
                        ? AppTheme.success.withOpacity(0.1)
                        : AppTheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasReport
                          ? AppTheme.success.withOpacity(0.3)
                          : AppTheme.error.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        hasReport
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: hasReport ? AppTheme.success : AppTheme.error,
                        size: 28,
                      ),
                      const SizedBox(height: 6),
                      Text('Shift $shift',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      if (hasReport)
                        Text(
                          AppUtils.formatDeviation(rep.deviation),
                          style: TextStyle(
                            fontSize: 11,
                            color: rep.deviation >= 0
                                ? AppTheme.deviationPositive
                                : AppTheme.deviationNegative,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      else
                        Text('Missing',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppTheme.error)),
                    ],
                  ),
                ),
              );
            }),
          ),
          if (rp.todays24HourDeviation != null) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('24-Hour Deviation',
                    style: Theme.of(context).textTheme.titleSmall),
                Text(
                  AppUtils.formatDeviation(rp.todays24HourDeviation!),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: rp.todays24HourDeviation! >= 0
                        ? AppTheme.deviationPositive
                        : AppTheme.deviationNegative,
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            const Center(
              child: Text(
                '⚠ 24-Hour result is incomplete — not all shifts submitted',
                style: TextStyle(color: AppTheme.warning, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIntervalCTA(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/admin/date-interval'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppTheme.accentGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accent.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_rounded,
                color: Colors.white, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date Interval Report',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    'View commissions & deviations over any date range',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  // ── Reports Tab ──────────────────────────────────────────────────
  Widget _buildReportsTab(BuildContext context, ReportProvider rp) {
    if (rp.isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary));
    }

    final filtered = rp.filteredReports;

    return Column(
      children: [
        // Filter bar
        _buildFilterBar(context, rp),

        // Reports count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Text(
                '${filtered.length} reports',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              if (rp.filterStart != null || rp.filterEmployeeId != null)
                TextButton(
                  onPressed: rp.clearFilters,
                  child: const Text('Clear Filters',
                      style: TextStyle(color: AppTheme.error, fontSize: 12)),
                ),
            ],
          ),
        ),

        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No reports found'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) =>
                      _buildAdminReportCard(context, filtered[i], i),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterBar(BuildContext context, ReportProvider rp) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: AppTheme.bgCard,
      child: Row(
        children: [
          // Employee filter
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: rp.filterEmployeeId?.isEmpty ?? true
                    ? null
                    : rp.filterEmployeeId,
                hint: const Text('All Employees',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                dropdownColor: AppTheme.bgCard,
                style: const TextStyle(
                    color: AppTheme.textPrimary, fontSize: 12),
                items: [
                  const DropdownMenuItem(
                      value: null, child: Text('All Employees')),
                  ...rp.employees.map((e) => DropdownMenuItem(
                        value: e.id,
                        child: Text(e.name),
                      )),
                ],
                onChanged: (v) => rp.setFilters(
                  start: rp.filterStart,
                  end: rp.filterEnd,
                  employeeId: v,
                  shift: rp.filterShift,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Shift filter
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: rp.filterShift,
              hint: const Text('All Shifts',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              dropdownColor: AppTheme.bgCard,
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontSize: 12),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Shifts')),
                ...List.generate(3, (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text('Shift ${i + 1}'),
                    )),
              ],
              onChanged: (v) => rp.setFilters(
                start: rp.filterStart,
                end: rp.filterEnd,
                employeeId: rp.filterEmployeeId,
                shift: v,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminReportCard(
      BuildContext context, ShiftReport report, int index) {
    final devColor = report.deviation > 0
        ? AppTheme.deviationPositive
        : report.deviation < 0
            ? AppTheme.deviationNegative
            : AppTheme.deviationZero;

    return GestureDetector(
      onTap: () => context.push('/admin/report/${report.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.bgBorder),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Shift badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    report.shiftLabel,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  AppUtils.formatDate(report.operatingDate),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    report.employeeName,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                StatusBadge(status: report.status),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _miniInfo(context, 'Deposit',
                    AppUtils.formatCurrency(report.totalDeposit)),
                _miniInfo(context, 'Withdrawal',
                    AppUtils.formatCurrency(report.totalWithdrawal)),
                _miniInfo(context, 'Commission',
                    AppUtils.formatCurrency(report.totalCommission),
                    color: AppTheme.success),
                _miniInfo(context, 'Deviation',
                    AppUtils.formatDeviation(report.deviation),
                    color: devColor),
              ],
            ),
          ],
        ),
      ).animate(delay: Duration(milliseconds: index * 40)).fadeIn(),
    );
  }

  Widget _miniInfo(BuildContext context, String label, String value,
      {Color? color}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontSize: 10)),
          Text(
            value,
            style: TextStyle(
              color: color ?? AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── Daily Tab ────────────────────────────────────────────────────
  Widget _buildDailyTab(BuildContext context, ReportProvider rp) {
    if (rp.isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary));
    }

    final summaries = rp.getDailySummaries(rp.reports);

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: summaries.length,
      itemBuilder: (ctx, i) => _buildDaySummaryCard(context, summaries[i], i),
    );
  }

  Widget _buildDaySummaryCard(
      BuildContext context, DailySummary summary, int index) {
    final devColor = summary.dailyDeviation == null
        ? AppTheme.textMuted
        : summary.dailyDeviation! >= 0
            ? AppTheme.deviationPositive
            : AppTheme.deviationNegative;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: summary.isComplete
              ? AppTheme.bgBorder
              : AppTheme.error.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                AppUtils.formatDate(summary.date),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              if (!summary.isComplete)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                  ),
                  child: const Text('Incomplete',
                      style: TextStyle(
                          color: AppTheme.error,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ),
              if (summary.dailyDeviation != null) ...[
                const SizedBox(width: 8),
                Text(
                  AppUtils.formatDeviation(summary.dailyDeviation!),
                  style: TextStyle(
                    color: devColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _shiftCell(context, 1, summary.shift1),
              const SizedBox(width: 8),
              _shiftCell(context, 2, summary.shift2),
              const SizedBox(width: 8),
              _shiftCell(context, 3, summary.shift3),
            ],
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: index * 50)).fadeIn().slideY(
        begin: 0.05, end: 0);
  }

  Widget _shiftCell(BuildContext context, int num, ShiftReport? rep) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: rep != null
              ? AppTheme.bgSurface
              : AppTheme.error.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: rep != null
                ? AppTheme.bgBorder
                : AppTheme.error.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Text('S$num',
                style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            if (rep != null)
              Text(
                AppUtils.formatDeviation(rep.deviation),
                style: TextStyle(
                  color: rep.deviation >= 0
                      ? AppTheme.deviationPositive
                      : AppTheme.deviationNegative,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            else
              const Text('—',
                  style: TextStyle(
                      color: AppTheme.error, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _SummaryCardData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}
