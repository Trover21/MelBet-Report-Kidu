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
      final auth = context.read<AuthProvider>();
      if (!auth.isStrictAdmin && auth.user?.role == UserRole.manager) {
        context.read<ReportProvider>().setRestrictedTeams(auth.user?.teams);
      } else {
        context.read<ReportProvider>().setRestrictedTeams(null);
      }
      context.read<ReportProvider>().loadAll();
      context.read<AuthProvider>().loadAllUsers();
      context.read<AuthProvider>().loadTeams();
      context.read<AuthProvider>().loadTeamRequests();
    });
  }

  DateTime? _dailyFilterStart;
  DateTime? _dailyFilterEnd;
  String _dailyIntervalPreset = 'all';
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

              // ── Global Team Selector ───────────────────────────
              _buildGlobalTeamSelector(context, reports, auth),
              const SizedBox(height: 4),

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
                    _buildUsersTab(context, auth, reports),
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
          // Team management (Admin) or Team requests (Manager)
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(
                  auth.isStrictAdmin
                      ? Icons.groups_rounded
                      : Icons.group_add_rounded,
                  color: AppTheme.accent,
                ),
                tooltip: auth.isStrictAdmin
                    ? 'Manage Teams & Requests'
                    : 'Manage My Teams',
                onPressed: () => _showTeamManagementDialog(context, auth),
              ),
              if (auth.isStrictAdmin &&
                  auth.teamRequests.any((r) => r.isPending))
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: AppTheme.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          // Change Password button (Admin can change pw)
          IconButton(
            icon: const Icon(Icons.key_rounded, color: AppTheme.textSecondary),
            tooltip: 'Change Password',
            onPressed: () => _showChangePasswordDialog(context),
          ),
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

  Widget _buildGlobalTeamSelector(
      BuildContext context, ReportProvider rp, AuthProvider auth) {
    final isManager = !auth.isStrictAdmin && auth.user?.role == UserRole.manager;
    final managerTeams = auth.user?.teams ?? (auth.user != null ? [auth.user!.teamName] : <String>[]);

    final allTeamOptions = isManager
        ? (managerTeams.toList()..sort())
        : (<String>{
            ...rp.availableTeamNames,
            ...auth.teams,
          }.toList()
            ..sort());

    final defaultTeamLabel = isManager
        ? (managerTeams.length > 1
            ? 'All My Assigned Teams (${managerTeams.join(", ")})'
            : (managerTeams.isNotEmpty ? managerTeams.first : 'My Assigned Team'))
        : 'All Teams (Organization Wide)';

    final hasTeamFilter =
        rp.filterTeamName != null && rp.filterTeamName!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasTeamFilter
              ? AppTheme.accent.withOpacity(0.6)
              : AppTheme.bgBorder,
          width: hasTeamFilter ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.groups_outlined,
            size: 18,
            color: hasTeamFilter ? AppTheme.accent : AppTheme.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            'Team:',
            style: TextStyle(
              color: hasTeamFilter ? AppTheme.accent : AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: rp.filterTeamName,
                hint: Text(
                  defaultTeamLabel,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                dropdownColor: AppTheme.bgCard,
                style: const TextStyle(
                  color: AppTheme.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(
                      defaultTeamLabel,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                  ...allTeamOptions.map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(
                          t,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      )),
                ],
                onChanged: (v) {
                  rp.setTeamFilter(v);
                },
              ),
            ),
          ),
          if (hasTeamFilter) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.18),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                rp.filterTeamName!,
                style: const TextStyle(
                  color: AppTheme.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded,
                  size: 16, color: AppTheme.error),
              tooltip: 'Clear team filter',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
              onPressed: () => rp.setTeamFilter(null),
            ),
          ],
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
                  rp.filterTeamName != null
                      ? "Today's Reports • ${rp.filterTeamName} (${AppUtils.formatDate(DateTime.now())})"
                      : "Today's Shift Reports (${AppUtils.formatDate(DateTime.now())})",
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
              if (rp.filterStart != null ||
                  rp.filterEmployeeId != null ||
                  rp.filterShift != null ||
                  rp.filterTeamName != null ||
                  rp.filterTeamNumber != null)
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
                  teamNumber: rp.filterTeamNumber,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Team filter
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: rp.filterTeamName,
              hint: const Text('All Teams',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              dropdownColor: AppTheme.bgCard,
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontSize: 12),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Teams')),
                ...rp.availableTeamNames.map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(t),
                    )),
              ],
              onChanged: (v) => rp.setFilters(
                start: rp.filterStart,
                end: rp.filterEnd,
                employeeId: rp.filterEmployeeId,
                shift: rp.filterShift,
                teamName: v,
              ),
            ),
          ),
          const SizedBox(width: 8),
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
                teamNumber: rp.filterTeamNumber,
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
                const SizedBox(width: 6),
                // Team badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue.withOpacity(0.4)),
                  ),
                  child: Text(
                    report.teamName,
                    style: const TextStyle(
                      color: Colors.lightBlueAccent,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
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

    final reportsForDaily = rp.filterTeamName != null
        ? rp.reports
            .where((r) =>
                r.teamName.toLowerCase() == rp.filterTeamName!.toLowerCase() ||
                'Team ${r.teamNumber}'.toLowerCase() ==
                    rp.filterTeamName!.toLowerCase())
            .toList()
        : rp.reports;

    final allSummaries = rp.getDailySummaries(reportsForDaily);

    // Filter summaries by selected interval
    final summaries = allSummaries.where((s) {
      final sDate = DateTime(s.date.year, s.date.month, s.date.day);
      if (_dailyFilterStart != null) {
        final start = DateTime(_dailyFilterStart!.year, _dailyFilterStart!.month, _dailyFilterStart!.day);
        if (sDate.isBefore(start)) return false;
      }
      if (_dailyFilterEnd != null) {
        final end = DateTime(_dailyFilterEnd!.year, _dailyFilterEnd!.month, _dailyFilterEnd!.day);
        if (sDate.isAfter(end)) return false;
      }
      return true;
    }).toList();

    // Calculate total deviation, expected, actual across the interval
    final totalIntervalDeviation = summaries.fold<double>(
      0.0,
      (sum, s) => sum + (s.dailyDeviation ?? 0.0),
    );
    final totalIntervalExpected = summaries.fold<double>(
      0.0,
      (sum, s) => sum + s.expectedAmount,
    );
    final totalIntervalActual = summaries.fold<double>(
      0.0,
      (sum, s) => sum + s.actualAmount,
    );

    return Column(
      children: [
        // ── Interval Selector Filter Header ────────────────────────
        _buildDailyIntervalFilterBar(context),

        // ── List of Daily Summaries ────────────────────────────────
        Expanded(
          child: summaries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.date_range_outlined,
                          size: 48, color: AppTheme.textMuted),
                      const SizedBox(height: 12),
                      Text(
                        'No shift reports in this interval',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppTheme.textMuted,
                            ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _dailyFilterStart = null;
                            _dailyFilterEnd = null;
                            _dailyIntervalPreset = 'all';
                          });
                        },
                        child: const Text('Reset Interval Filter'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                  itemCount: summaries.length,
                  itemBuilder: (ctx, i) =>
                      _buildDaySummaryCard(context, summaries[i], i),
                ),
        ),

        // ── Total Deviation in Interval (Bottom Bar) ───────────────
        _buildDailyIntervalBottomBar(
          context,
          count: summaries.length,
          totalDeviation: totalIntervalDeviation,
          totalExpected: totalIntervalExpected,
          totalActual: totalIntervalActual,
        ),
      ],
    );
  }

  Widget _buildDailyIntervalFilterBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        border: Border(bottom: BorderSide(color: AppTheme.bgBorder)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Icon(Icons.date_range_rounded, size: 16, color: AppTheme.accent),
            const SizedBox(width: 8),
            _intervalPresetChip('All Time', 'all', () {
              setState(() {
                _dailyFilterStart = null;
                _dailyFilterEnd = null;
                _dailyIntervalPreset = 'all';
              });
            }),
            const SizedBox(width: 6),
            _intervalPresetChip('7 Days', '7d', () {
              final now = DateTime.now();
              setState(() {
                _dailyFilterEnd = now;
                _dailyFilterStart = now.subtract(const Duration(days: 6));
                _dailyIntervalPreset = '7d';
              });
            }),
            const SizedBox(width: 6),
            _intervalPresetChip('15 Days', '15d', () {
              final now = DateTime.now();
              setState(() {
                _dailyFilterEnd = now;
                _dailyFilterStart = now.subtract(const Duration(days: 14));
                _dailyIntervalPreset = '15d';
              });
            }),
            const SizedBox(width: 6),
            _intervalPresetChip('30 Days', '30d', () {
              final now = DateTime.now();
              setState(() {
                _dailyFilterEnd = now;
                _dailyFilterStart = now.subtract(const Duration(days: 29));
                _dailyIntervalPreset = '30d';
              });
            }),
            const SizedBox(width: 6),
            _intervalPresetChip(
              _dailyFilterStart != null && _dailyIntervalPreset == 'custom'
                  ? '${AppUtils.formatDate(_dailyFilterStart!)} – ${AppUtils.formatDate(_dailyFilterEnd ?? DateTime.now())}'
                  : 'Custom Range',
              'custom',
              () async {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2022),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                  initialDateRange: _dailyFilterStart != null && _dailyFilterEnd != null
                      ? DateTimeRange(start: _dailyFilterStart!, end: _dailyFilterEnd!)
                      : DateTimeRange(
                          start: DateTime.now().subtract(const Duration(days: 7)),
                          end: DateTime.now(),
                        ),
                  builder: (ctx, child) => Theme(
                    data: AppTheme.darkTheme,
                    child: child!,
                  ),
                );
                if (range != null) {
                  setState(() {
                    _dailyFilterStart = range.start;
                    _dailyFilterEnd = range.end;
                    _dailyIntervalPreset = 'custom';
                  });
                }
              },
            ),
            if (_dailyFilterStart != null) ...[
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 16, color: AppTheme.error),
                tooltip: 'Clear interval filter',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                onPressed: () {
                  setState(() {
                    _dailyFilterStart = null;
                    _dailyFilterEnd = null;
                    _dailyIntervalPreset = 'all';
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _intervalPresetChip(String label, String key, VoidCallback onTap) {
    final isSelected = _dailyIntervalPreset == key;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accent : AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.accent : AppTheme.bgBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildDailyIntervalBottomBar(
    BuildContext context, {
    required int count,
    required double totalDeviation,
    required double totalExpected,
    required double totalActual,
  }) {
    final devColor = totalDeviation > 0
        ? AppTheme.deviationPositive
        : totalDeviation < 0
            ? AppTheme.deviationNegative
            : AppTheme.deviationZero;

    final dateRangeLabel = _dailyFilterStart != null
        ? '${AppUtils.formatDate(_dailyFilterStart!)} – ${AppUtils.formatDate(_dailyFilterEnd ?? DateTime.now())}'
        : 'All Available Days';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        border: Border(
          top: BorderSide(color: AppTheme.primary.withOpacity(0.4), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.analytics_outlined,
                              size: 15, color: AppTheme.accent),
                          const SizedBox(width: 6),
                          Text(
                            'Interval Total: $count Day(s)',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateRangeLabel,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'TOTAL DEVIATION',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppUtils.formatDeviation(totalDeviation),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: devColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.bgSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Exp Total: ${AppUtils.formatCurrency(totalExpected)}',
                    style: const TextStyle(
                      color: AppTheme.warning,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Act Total: ${AppUtils.formatCurrency(totalActual)}',
                    style: const TextStyle(
                      color: AppTheme.success,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
          const SizedBox(height: 10),
          const Divider(color: AppTheme.bgBorder, height: 1),
          const SizedBox(height: 10),
          // Expected & Actual row (clean, non-editable)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.bgSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.bgBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.trending_up_rounded,
                          color: AppTheme.warning, size: 15),
                      const SizedBox(width: 6),
                      Text(
                        'Expected: ${AppUtils.formatCurrency(summary.expectedAmount)}',
                        style: const TextStyle(
                          color: AppTheme.warning,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 20,
                  width: 1,
                  color: AppTheme.bgBorder,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_rounded,
                          color: AppTheme.success, size: 15),
                      const SizedBox(width: 6),
                      Text(
                        'Actual: ${AppUtils.formatCurrency(summary.actualAmount)}',
                        style: const TextStyle(
                          color: AppTheme.success,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
  Widget _buildUsersTab(
      BuildContext context, AuthProvider auth, ReportProvider rp) {
    final allUsers = auth.allUsers;
    final selectedTeam = rp.filterTeamName;
    final isManager = !auth.isStrictAdmin && auth.user?.role == UserRole.manager;
    final managerTeams = auth.user?.teams ?? (auth.user != null ? [auth.user!.teamName] : <String>[]);

    // 1. Manager can only see his own detail and his employees (not overall employees and not other managers)
    final baseUsers = isManager
        ? allUsers.where((u) {
            if (u.id == auth.user?.id) return true;
            if (u.role == UserRole.employee) {
              return managerTeams.any((t) =>
                  t.toLowerCase() == u.teamName.toLowerCase() ||
                  t.toLowerCase() == 'Team ${u.teamNumber}'.toLowerCase());
            }
            return false;
          }).toList()
        : allUsers;

    final filteredByTeam = (selectedTeam == null || selectedTeam.isEmpty)
        ? baseUsers
        : baseUsers.where((u) {
            if (u.role == UserRole.admin) return true;
            if (u.role == UserRole.manager) {
              return u.teams
                      .any((t) => t.toLowerCase() == selectedTeam.toLowerCase()) ||
                  u.teamName.toLowerCase() == selectedTeam.toLowerCase();
            }
            return u.teamName.toLowerCase() == selectedTeam.toLowerCase() ||
                'Team ${u.teamNumber}'.toLowerCase() ==
                    selectedTeam.toLowerCase();
          }).toList();

    final pending = filteredByTeam.where((u) => !u.isApproved).toList();
    final active = filteredByTeam.where((u) => u.isApproved && u.isActive).toList();
    final disabled =
        filteredByTeam.where((u) => u.isApproved && !u.isActive).toList();

    List<AppUser> displayedUsers;
    if (_userFilter == 'pending') {
      displayedUsers = pending;
    } else if (_userFilter == 'active') {
      displayedUsers = active;
    } else if (_userFilter == 'disabled') {
      displayedUsers = disabled;
    } else {
      displayedUsers = filteredByTeam;
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
                  selectedTeam != null
                      ? '${filteredByTeam.length} account(s) in $selectedTeam • ${pending.length} pending'
                      : (isManager
                          ? '${baseUsers.length} account(s) in your team(s) • ${pending.length} pending'
                          : '${allUsers.length} registered account(s) • ${pending.length} pending approval'),
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

        if (isManager)
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
                    'Manager View: You have visibility into your profile and your assigned team employees. Overall organization employees and other managers are hidden.',
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
              _filterChip('all', 'All (${baseUsers.length})'),
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
      BuildContext context, AuthProvider auth, AppUser user) {
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
                    if (user.role != UserRole.admin) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          user.role == UserRole.manager
                              ? 'TEAMS: ${user.teams.join(", ")}'
                              : user.teamName.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.lightBlueAccent,
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
          if (auth.isStrictAdmin && user.role != UserRole.admin && !isPending) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.delete_forever_rounded, color: AppTheme.error, size: 20),
              tooltip: 'Remove User',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppTheme.bgCard,
                    title: const Row(
                      children: [
                        Icon(Icons.delete_forever_rounded, color: AppTheme.error, size: 24),
                        SizedBox(width: 8),
                        Text('Remove User'),
                      ],
                    ),
                    content: Text(
                        'Are you sure you want to permanently remove ${user.name} (${user.role.name}) from the organization?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.error,
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Remove Permanently'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  final err = await auth.deleteUser(user.id);
                  if (context.mounted) {
                    if (err == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${user.name} removed successfully.'),
                          backgroundColor: AppTheme.success,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to remove user: $err'),
                          backgroundColor: AppTheme.error,
                        ),
                      );
                    }
                  }
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final curPwCtrl = TextEditingController();
    final newPwCtrl = TextEditingController();
    final confirmPwCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureCur = true;
    bool obscureNew = true;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: AppTheme.bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.key_rounded, color: AppTheme.primary, size: 22),
              SizedBox(width: 10),
              Text('Change Password'),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: curPwCtrl,
                    obscureText: obscureCur,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(obscureCur ? Icons.visibility_off : Icons.visibility, size: 18),
                        onPressed: () => setDlgState(() => obscureCur = !obscureCur),
                      ),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Current password is required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: newPwCtrl,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, size: 18),
                        onPressed: () => setDlgState(() => obscureNew = !obscureNew),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'New password is required';
                      if (v.length < 6) return 'At least 6 characters required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmPwCtrl,
                    obscureText: obscureNew,
                    decoration: const InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: Icon(Icons.check_circle_outline, size: 20),
                    ),
                    validator: (v) => v != newPwCtrl.text ? 'Passwords do not match' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDlgState(() => isSaving = true);
                      final auth = context.read<AuthProvider>();
                      final err = await auth.changePassword(
                        currentPassword: curPwCtrl.text,
                        newPassword: newPwCtrl.text,
                      );
                      setDlgState(() => isSaving = false);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(err ?? 'Password changed successfully!'),
                            backgroundColor: err == null ? const Color(0xFF22C55E) : AppTheme.error,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
              child: isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Update Password'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTeamManagementDialog(BuildContext context, AuthProvider auth) {
    if (auth.isStrictAdmin) {
      _showAdminTeamDialog(context, auth);
    } else {
      _showManagerTeamRequestDialog(context, auth);
    }
  }

  void _showAdminTeamDialog(BuildContext context, AuthProvider auth) {
    final newTeamCtrl = TextEditingController();
    bool isAdding = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final pendingReqs = auth.teamRequests.where((r) => r.isPending).toList();
          return AlertDialog(
            backgroundColor: AppTheme.bgCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.groups_rounded, color: AppTheme.primary, size: 24),
                const SizedBox(width: 10),
                const Text('Teams & Manager Requests'),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Add New Team
                    Text(
                      'Push New Team Dynamically',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppTheme.accent,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Teams created here immediately appear in the employee & manager registration dropdowns.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: newTeamCtrl,
                            decoration: const InputDecoration(
                              hintText: 'e.g. Team 4, Night Shift, Alpha...',
                              prefixIcon: Icon(Icons.add_circle_outline, size: 20),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: isAdding
                              ? null
                              : () async {
                                  final name = newTeamCtrl.text.trim();
                                  if (name.isEmpty) return;
                                  setDlgState(() => isAdding = true);
                                  final err = await auth.addTeam(name);
                                  setDlgState(() => isAdding = false);
                                  if (err == null) {
                                    newTeamCtrl.clear();
                                    setDlgState(() {});
                                    if (ctx.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Team "$name" created successfully!'),
                                          backgroundColor: const Color(0xFF22C55E),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  } else {
                                    if (ctx.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(err),
                                          backgroundColor: AppTheme.error,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  }
                                },
                          child: isAdding
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Add Team'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppTheme.bgBorder),
                    const SizedBox(height: 8),

                    // Section 2: Active Teams List
                    Text(
                      'Active Teams (${auth.teams.length})',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: auth.teams.map((t) {
                        return InputChip(
                          avatar: const Icon(Icons.check_circle, size: 16, color: AppTheme.primary),
                          label: Text(t, style: const TextStyle(fontWeight: FontWeight.w600)),
                          backgroundColor: AppTheme.bgSurface,
                          side: const BorderSide(color: AppTheme.bgBorder),
                          deleteIcon: const Icon(Icons.cancel, size: 16, color: AppTheme.error),
                          deleteButtonTooltipMessage: 'Remove $t from organization',
                          onDeleted: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                backgroundColor: AppTheme.bgCard,
                                title: const Text('Remove Team?'),
                                content: Text('Are you sure you want to remove "$t" from the organization?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(c, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                                    onPressed: () => Navigator.pop(c, true),
                                    child: const Text('Remove'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              final err = await auth.removeTeam(t);
                              setDlgState(() {});
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(err ?? 'Team "$t" removed.'),
                                    backgroundColor: err == null ? const Color(0xFF22C55E) : AppTheme.error,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppTheme.bgBorder),
                    const SizedBox(height: 8),

                    // Section 3: Manager Team Requests
                    Row(
                      children: [
                        Text(
                          'Manager Team Requests',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: AppTheme.accent,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(width: 8),
                        if (pendingReqs.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.error,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${pendingReqs.length} PENDING',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (auth.teamRequests.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'No manager team requests yet.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
                        ),
                      )
                    else
                      ...auth.teamRequests.map((req) {
                        final isPend = req.isPending;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.bgSurface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isPend ? AppTheme.accent.withOpacity(0.5) : AppTheme.bgBorder,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    req.userName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: req.isApproved
                                          ? AppTheme.success.withOpacity(0.2)
                                          : req.isRejected
                                              ? AppTheme.error.withOpacity(0.2)
                                              : AppTheme.accent.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      req.status.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: req.isApproved
                                            ? AppTheme.success
                                            : req.isRejected
                                                ? AppTheme.error
                                                : AppTheme.accent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Requested Teams: ${req.requestedTeams.join(", ")}',
                                style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              if (req.reason.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Reason: ${req.reason}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
                                ),
                              ],
                              if (isPend) ...[
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.error,
                                        side: const BorderSide(color: AppTheme.error),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      ),
                                      onPressed: () async {
                                        await auth.rejectTeamRequest(req.id);
                                        setDlgState(() {});
                                      },
                                      child: const Text('Reject', style: TextStyle(fontSize: 12)),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.success,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      ),
                                      onPressed: () async {
                                        await auth.approveTeamRequest(req.id);
                                        setDlgState(() {});
                                        if (ctx.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Request approved! Teams assigned to manager.'),
                                              backgroundColor: AppTheme.success,
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      },
                                      child: const Text('Approve', style: TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showManagerTeamRequestDialog(BuildContext context, AuthProvider auth) {
    final selectedTeams = <String>{};
    final reasonCtrl = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final currentTeams = auth.user?.teams ?? [];
          final availableToRequest = auth.teams.where((t) => !currentTeams.contains(t)).toList();
          final myRequests = auth.teamRequests;

          return AlertDialog(
            backgroundColor: AppTheme.bgCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.groups_rounded, color: AppTheme.accent, size: 22),
                const SizedBox(width: 10),
                const Text('My Teams & Requests'),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Currently Managed Teams (With Remove Option)
                    Row(
                      children: [
                        Text(
                          'Currently Managing (${currentTeams.length})',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Text(
                          'Tap ✕ to remove',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (currentTeams.isEmpty)
                      Text(
                        'No teams currently assigned.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: currentTeams.map((t) => InputChip(
                          avatar: const Icon(Icons.check_circle, size: 14, color: AppTheme.primary),
                          label: Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          backgroundColor: AppTheme.primary.withOpacity(0.12),
                          side: const BorderSide(color: AppTheme.primary),
                          deleteIcon: const Icon(Icons.cancel, size: 16, color: AppTheme.error),
                          deleteButtonTooltipMessage: 'Remove $t from your managed teams',
                          onDeleted: () async {
                            if (currentTeams.length <= 1) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('You must manage at least one team. Cannot remove your only team.'),
                                    backgroundColor: AppTheme.error,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                              return;
                            }
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                backgroundColor: AppTheme.bgCard,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                title: const Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 22),
                                    SizedBox(width: 8),
                                    Text('Remove Team?'),
                                  ],
                                ),
                                content: Text(
                                  'Are you sure you want to remove "$t" from your managed teams? You will no longer manage reports for this team.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(c, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                                    onPressed: () => Navigator.pop(c, true),
                                    child: const Text('Remove'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              final err = await auth.removeManagerTeam(t);
                              if (context.mounted) {
                                final rp = context.read<ReportProvider>();
                                if (rp.filterTeamName == t) {
                                  rp.setTeamFilter(null);
                                }
                              }
                              setDlgState(() {});
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(err ?? 'Team "$t" removed from your managed list.'),
                                    backgroundColor: err == null ? const Color(0xFF22C55E) : AppTheme.error,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                        )).toList(),
                      ),
                    const SizedBox(height: 16),
                    const Divider(color: AppTheme.bgBorder),
                    const SizedBox(height: 8),

                    // Section 2: Request Additional Teams
                    Text(
                      'Request Additional Teams from Admin',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppTheme.accent,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select teams you need and submit to administrator for approval.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 10),
                    if (availableToRequest.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.bgSurface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.bgBorder),
                        ),
                        child: Text(
                          'You are already managing all active teams or no additional teams exist.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: availableToRequest.map((team) {
                          final isSel = selectedTeams.contains(team);
                          return FilterChip(
                            avatar: Icon(
                              isSel ? Icons.check_circle : Icons.add_circle_outline,
                              size: 16,
                              color: isSel ? Colors.white : AppTheme.textSecondary,
                            ),
                            label: Text(team),
                            selected: isSel,
                            selectedColor: AppTheme.primary,
                            showCheckmark: false,
                            labelStyle: TextStyle(
                              color: isSel ? Colors.white : AppTheme.textPrimary,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            ),
                            backgroundColor: AppTheme.bgSurface,
                            side: BorderSide(color: isSel ? AppTheme.primary : AppTheme.bgBorder),
                            onSelected: (sel) {
                              setDlgState(() {
                                if (sel) {
                                  selectedTeams.add(team);
                                } else {
                                  selectedTeams.remove(team);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    if (availableToRequest.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: reasonCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Reason for Request (Optional)',
                          hintText: 'e.g. Taking over weekend shifts, expanding coverage',
                          isDense: true,
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          icon: isSubmitting
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.send_rounded, size: 16),
                          label: const Text('Submit Request'),
                          onPressed: isSubmitting || selectedTeams.isEmpty
                              ? null
                              : () async {
                                  setDlgState(() => isSubmitting = true);
                                  final err = await auth.requestTeams(
                                    selectedTeams.toList(),
                                    reason: reasonCtrl.text.trim(),
                                  );
                                  setDlgState(() => isSubmitting = false);
                                  if (err == null) {
                                    selectedTeams.clear();
                                    reasonCtrl.clear();
                                    setDlgState(() {});
                                    if (ctx.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Team request sent to administrator for approval!'),
                                          backgroundColor: Color(0xFF22C55E),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  } else {
                                    if (ctx.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(err),
                                          backgroundColor: AppTheme.error,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  }
                                },
                        ),
                      ),
                    ],

                    // Section 3: My Team Requests Status
                    if (myRequests.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(color: AppTheme.bgBorder),
                      const SizedBox(height: 8),
                      Text(
                        'My Team Requests Status',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...myRequests.map((req) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.bgSurface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.bgBorder),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Requested: ${req.requestedTeams.join(", ")}',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                    if (req.reason.isNotEmpty)
                                      Text(
                                        'Note: ${req.reason}',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: req.isApproved
                                      ? AppTheme.success.withOpacity(0.2)
                                      : req.isRejected
                                          ? AppTheme.error.withOpacity(0.2)
                                          : AppTheme.accent.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  req.status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: req.isApproved
                                        ? AppTheme.success
                                        : req.isRejected
                                            ? AppTheme.error
                                            : AppTheme.accent,
                                  ),
                                ),
                              ),
                              if (req.isPending) ...[
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
                                  tooltip: 'Cancel Request',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                  onPressed: () async {
                                    await auth.cancelTeamRequest(req.id);
                                    setDlgState(() {});
                                  },
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          );
        },
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