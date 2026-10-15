import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';
import '../../data/models/shift_report_model.dart';
import '../../data/models/user_model.dart';
import 'widgets/status_badge.dart';
import '../../widgets/super_manager_report_card.dart';

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
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().loadAll();
      context.read<AuthProvider>().loadAllUsers();
    });
  }

  String _userFilter = 'all'; // 'all', 'pending', 'active', 'disabled'
  int _selectedTodayShift = 1; // 1, 2, 3, or 0 (0 = 24H aggregate)

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
                    _buildUsersTab(context, auth),
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
              Text(
                auth.user?.role == UserRole.manager
                    ? 'Manager Dashboard'
                    : 'Admin Dashboard',
                style: Theme.of(context).textTheme.titleLarge,
              ),
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
            tooltip: 'Log out',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Row(
                    children: [
                      Icon(Icons.logout_rounded, color: AppTheme.error, size: 22),
                      SizedBox(width: 8),
                      Text('Log Out'),
                    ],
                  ),
                  content: const Text(
                    'Do you want to log out?',
                    style: TextStyle(fontSize: 15),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Log Out'),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await auth.logout();
                if (context.mounted) {
                  context.go('/login');
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final pendingCount = context.watch<AuthProvider>().pendingUsers.length;

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
        tabs: [
          const Tab(text: 'Overview'),
          const Tab(text: 'Reports'),
          const Tab(text: 'Daily'),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Users'),
                if (pendingCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$pendingCount',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
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
    final s1 = todayReports.where((r) => r.shiftNumber == 1).firstOrNull;
    final s2 = todayReports.where((r) => r.shiftNumber == 2).firstOrNull;
    final s3 = todayReports.where((r) => r.shiftNumber == 3).firstOrNull;

    // Determine current report to display
    ShiftReport? selectedReport;
    if (_selectedTodayShift == 1) selectedReport = s1;
    if (_selectedTodayShift == 2) selectedReport = s2;
    if (_selectedTodayShift == 3) selectedReport = s3;

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
                  color: AppTheme.primary, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Today's Shift Reports (${AppUtils.formatDate(DateTime.now())})",
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Super Manager Format',
                  style: TextStyle(
                    color: AppTheme.accent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Shift Selector Tabs ──────────────────────────────────
          Row(
            children: [
              _shiftSelectorChip(
                label: 'Shift 1',
                shiftNum: 1,
                hasReport: s1 != null,
                dev: s1?.deviation,
                isSelected: _selectedTodayShift == 1,
                onTap: () => setState(() => _selectedTodayShift = 1),
              ),
              const SizedBox(width: 8),
              _shiftSelectorChip(
                label: 'Shift 2',
                shiftNum: 2,
                hasReport: s2 != null,
                dev: s2?.deviation,
                isSelected: _selectedTodayShift == 2,
                onTap: () => setState(() => _selectedTodayShift = 2),
              ),
              const SizedBox(width: 8),
              _shiftSelectorChip(
                label: 'Shift 3',
                shiftNum: 3,
                hasReport: s3 != null,
                dev: s3?.deviation,
                isSelected: _selectedTodayShift == 3,
                onTap: () => setState(() => _selectedTodayShift = 3),
              ),
              const SizedBox(width: 8),
              _shiftSelectorChip(
                label: '24H Total',
                shiftNum: 0,
                hasReport: todayReports.isNotEmpty,
                dev: rp.todays24HourDeviation,
                isSelected: _selectedTodayShift == 0,
                onTap: () => setState(() => _selectedTodayShift = 0),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Super Manager Format Report Card ─────────────────────
          if (_selectedTodayShift == 0) ...[
            // 24-Hour Aggregated Report
            if (todayReports.isEmpty)
              _emptyShiftState(context, 'No shifts submitted yet today')
            else
              _build24HourSuperManagerCard(context, rp, todayReports)
          ] else ...[
            // Single Shift Report
            if (selectedReport != null)
              SuperManagerReportCard.fromReport(selectedReport)
            else
              _emptyShiftState(
                context,
                'Shift $_selectedTodayShift has not been submitted yet today',
              ),
          ],
        ],
      ),
    );
  }

  Widget _shiftSelectorChip({
    required String label,
    required int shiftNum,
    required bool hasReport,
    double? dev,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primary.withOpacity(0.2)
                : AppTheme.bgSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primary
                  : (hasReport
                      ? AppTheme.bgBorder
                      : AppTheme.error.withOpacity(0.3)),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 3),
              if (hasReport && dev != null)
                Text(
                  AppUtils.formatDeviation(dev),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: dev >= 0
                        ? AppTheme.deviationPositive
                        : AppTheme.deviationNegative,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              else if (hasReport)
                const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 14)
              else
                const Text(
                  'Missing',
                  style: TextStyle(color: AppTheme.error, fontSize: 9),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _build24HourSuperManagerCard(
      BuildContext context, ReportProvider rp, List<ShiftReport> todayReports) {
    final sorted = List<ShiftReport>.from(todayReports)
      ..sort((a, b) => a.shiftNumber.compareTo(b.shiftNumber));

    final first = sorted.first;
    final last = sorted.last;

    final initReady = first.initialReddy;
    final initAcc = first.initialAccount;
    final depComm = todayReports.fold(0.0, (s, r) => s + r.depositCommission);
    final wdComm = todayReports.fold(0.0, (s, r) => s + r.withdrawalCommission);
    final totComm = depComm + wdComm;
    final endReady = last.endReddy;
    final endAcc = last.endBalance + last.transferToNext;

    final exp = initReady + initAcc + totComm;
    final act = endReady + endAcc;
    final dev = rp.todays24HourDeviation ?? (act - exp);

    return SuperManagerReportCard(
      title: '24-Hour Daily Total (${todayReports.length}/3 Shifts)',
      date: DateTime.now(),
      employeeName: todayReports.map((r) => 'S${r.shiftNumber}: ${r.employeeName}').join(', '),
      initialReddy: initReady,
      initialAccount: initAcc,
      depositCommission: depComm,
      withdrawalCommission: wdComm,
      totalCommission: totComm,
      endReddy: endReady,
      endAccount: endAcc,
      expected: exp,
      actual: act,
      deviation: dev,
    );
  }

  Widget _emptyShiftState(BuildContext context, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.error.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.schedule_rounded, color: AppTheme.warning, size: 36),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text(
            'The employee has not yet completed and submitted this shift report.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
            textAlign: TextAlign.center,
          ),
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

  // ── Users & Approvals Tab ───────────────────────────────────────
  Widget _buildUsersTab(BuildContext context, AuthProvider auth) {
    final allUsers = auth.allUsers;
    final pending = allUsers.where((u) => !u.isApproved).toList();
    final active = allUsers.where((u) => u.isApproved && u.isActive).toList();
    final disabled =
        allUsers.where((u) => u.isApproved && !u.isActive).toList();

    List<dynamic> displayedUsers;
    if (_userFilter == 'pending') {
      displayedUsers = pending;
    } else if (_userFilter == 'active') {
      displayedUsers = active;
    } else if (_userFilter == 'disabled') {
      displayedUsers = disabled;
    } else {
      displayedUsers = allUsers;
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Header ─────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'User Management',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  '${allUsers.length} registered account(s) • ${pending.length} pending approval',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: AppTheme.accent),
              onPressed: () => auth.loadAllUsers(),
              tooltip: 'Refresh user list',
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (!auth.isStrictAdmin)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.primary, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Manager View: You have full visibility into employees and reports. User approvals & account status changes are managed by Administrators.',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // ── Filter Chips ───────────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterChip('all', 'All (${allUsers.length})'),
              const SizedBox(width: 8),
              _filterChip('pending', 'Pending (${pending.length})',
                  badgeColor: pending.isNotEmpty ? AppTheme.warning : null),
              const SizedBox(width: 8),
              _filterChip('active', 'Active (${active.length})',
                  badgeColor: AppTheme.success),
              const SizedBox(width: 8),
              _filterChip('disabled', 'Disabled (${disabled.length})',
                  badgeColor: disabled.isNotEmpty ? AppTheme.error : null),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // ── Empty State ────────────────────────────────────────
        if (displayedUsers.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  const Icon(Icons.people_outline,
                      size: 56, color: AppTheme.textMuted),
                  const SizedBox(height: 12),
                  Text(
                    'No users found in this category',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          )
        else
          ...displayedUsers
              .map((user) => _buildManagedUserCard(context, auth, user)),
      ],
    );
  }

  Widget _filterChip(String key, String label, {Color? badgeColor}) {
    final isSelected = _userFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _userFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary
                : (badgeColor?.withOpacity(0.4) ?? AppTheme.bgBorder),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildManagedUserCard(
      BuildContext context, AuthProvider auth, dynamic user) {
    final isPending = !user.isApproved;
    final isActive = user.isApproved && user.isActive;
    final isDisabled = user.isApproved && !user.isActive;

    Color statusColor;
    String statusLabel;
    if (isPending) {
      statusColor = AppTheme.warning;
      statusLabel = 'Pending Approval';
    } else if (isActive) {
      statusColor = AppTheme.success;
      statusLabel = 'Active';
    } else {
      statusColor = AppTheme.error;
      statusLabel = 'Disabled';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDisabled
              ? AppTheme.error.withOpacity(0.3)
              : AppTheme.bgBorder,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: statusColor.withOpacity(0.18),
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.name,
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (user.role == UserRole.admin) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'ADMIN',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accent,
                          ),
                        ),
                      ),
                    ] else if (user.role == UserRole.manager) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'MANAGER',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'EMPLOYEE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.tealAccent,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '@${user.username} • ${user.email ?? "No email"}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // ── Actions (Admin Only) ─────────────────────────────
          if (isPending) ...[
            if (auth.isStrictAdmin) ...[
              // Reject Sign Up
              IconButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Reject Registration'),
                      content: Text(
                          'Reject sign-up request for ${user.name}? This will remove the request.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.error),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Reject'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    final ok = await auth.rejectUser(user.id);
                    if (context.mounted && ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Registration for ${user.name} rejected'),
                          backgroundColor: AppTheme.error,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.close, color: AppTheme.error),
                tooltip: 'Reject request',
              ),
              // Approve Sign Up
              ElevatedButton.icon(
                onPressed: () async {
                  final ok = await auth.approveUser(user.id);
                  if (context.mounted && ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Approved ${user.name}! They can now log in.'),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Approve'),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_clock, size: 13, color: AppTheme.warning),
                    SizedBox(width: 4),
                    Text(
                      'Admin Only',
                      style: TextStyle(
                        color: AppTheme.warning,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ] else if (auth.isStrictAdmin && isActive && user.role != UserRole.admin) ...[
            // Disable User (when user interrupts or leaves job)
            OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Disable User Account'),
                    content: Text(
                        'Are you sure you want to disable ${user.name}?\n\nThey will be prevented from logging in or submitting shifts until re-enabled by an admin.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.error),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Disable Account'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  final ok = await auth.setUserActive(user.id, false);
                  if (context.mounted && ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${user.name} has been disabled'),
                        backgroundColor: AppTheme.warning,
                      ),
                    );
                  }
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.error,
                side: const BorderSide(color: AppTheme.error),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.block, size: 14),
              label: const Text('Disable'),
            ),
          ] else if (auth.isStrictAdmin && isDisabled) ...[
            // Re-Enable User
            ElevatedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Enable User Account'),
                    content: Text(
                        'Re-activate account for ${user.name}? They will be able to log in again.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Re-Enable'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  final ok = await auth.setUserActive(user.id, true);
                  if (context.mounted && ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '${user.name} re-enabled! They can now log in.'),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.check_circle_outline, size: 15),
              label: const Text('Enable'),
            ),
          ],
        ],
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
