import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/employee/employee_home_screen.dart';
import '../../screens/employee/shift_report_form_screen.dart';
import '../../screens/employee/report_detail_screen.dart';
import '../../screens/admin/admin_dashboard_screen.dart';
import '../../screens/admin/report_detail_admin_screen.dart';
import '../../screens/admin/date_interval_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    final auth = context.read<AuthProvider>();
    final isLoggedIn = auth.isAuthenticated;
    final isLogin = state.matchedLocation == '/login';

    if (!isLoggedIn && !isLogin) return '/login';
    if (isLoggedIn && isLogin) {
      return auth.isAdmin ? '/admin' : '/employee';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (ctx, state) => const LoginScreen(),
    ),
    // ── Employee Routes ──────────────────────────────────────────
    GoRoute(
      path: '/employee',
      name: 'employee-home',
      builder: (ctx, state) => const EmployeeHomeScreen(),
      routes: [
        GoRoute(
          path: 'submit-report',
          name: 'submit-report',
          builder: (ctx, state) => const ShiftReportFormScreen(),
        ),
        GoRoute(
          path: 'report/:id',
          name: 'employee-report-detail',
          builder: (ctx, state) =>
              ReportDetailScreen(reportId: state.pathParameters['id']!),
        ),
      ],
    ),
    // ── Admin Routes ─────────────────────────────────────────────
    GoRoute(
      path: '/admin',
      name: 'admin-dashboard',
      builder: (ctx, state) => const AdminDashboardScreen(),
      routes: [
        GoRoute(
          path: 'report/:id',
          name: 'admin-report-detail',
          builder: (ctx, state) =>
              ReportDetailAdminScreen(reportId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: 'date-interval',
          name: 'date-interval',
          builder: (ctx, state) => const DateIntervalScreen(),
        ),
      ],
    ),
  ],
);
