import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'data/mock/mock_repository.dart';
import 'providers/auth_provider.dart';
import 'providers/report_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait on mobile; allow all on desktop/web
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  final repo = MockRepository();
  final authProvider = AuthProvider(repo);
  await authProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => ReportProvider(repo)),
      ],
      child: const MelbetApp(),
    ),
  );
}

class MelbetApp extends StatelessWidget {
  const MelbetApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuild router when auth state changes
    context.watch<AuthProvider>();

    return MaterialApp.router(
      title: 'Melbet Shift Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
