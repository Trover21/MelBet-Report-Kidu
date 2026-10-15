import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/api_client.dart';
import 'data/repositories/api_repository.dart';
import 'providers/auth_provider.dart';
import 'providers/report_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // ── Wire up repository (switch to MockRepository() for offline dev) ──
  final apiClient = ApiClient.instance;
  final repo = ApiRepository(apiClient);
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
    context.watch<AuthProvider>();

    return MaterialApp.router(
      title: 'Melbet Shift Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
