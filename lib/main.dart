import 'dart:async';
import 'package:maliza/core/api/remote_db_updater.dart';
import 'package:maliza/core/data/account_cache.dart';
import 'package:maliza/features/app/provider/profile_provider.dart';
import 'package:maliza/features/app/provider/route_navigation_provider.dart';
import 'package:maliza/features/app/provider/task_provider.dart';
import 'package:maliza/features/app/provider/weather_provider.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:maliza/core/config/config_global.dart';
import 'package:maliza/core/routes/app_router.dart';
import 'package:maliza/core/routes/app_routes.dart';
import 'package:maliza/core/theme/theme_config.dart';
import 'package:maliza/features/auth/provider/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final bool isLogined = await AccountCache.isLogined() ?? false;
  await initializeDateFormatting('fr_FR');

    Timer.periodic(const Duration(seconds: 10), (timer) async {
      await _performRemoteSync();
    });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => RouteNavigationProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: MyApp(isLogined: isLogined),
    ),
  );
}

Future<void> _performRemoteSync() async {
  try {
    final currentId = await AccountCache.getCurrentAccountId() ?? 0;
    final remoteUpdater = RemoteDbUpdater(currentId: currentId);
    final response = await remoteUpdater.syncAll();

    if (!response.success) {
      debugPrint('Sync distant échoué: ${response.message}');
    }
  } catch (e) {
    debugPrint('Erreur sync distant: $e');
  }
}

class MyApp extends StatelessWidget {
  final bool isLogined;

  const MyApp({super.key, required this.isLogined});

  @override
  Widget build(BuildContext context) {
    return FTheme(
      data: ThemeConfig.lightTheme,
      child: MaterialApp(
        title: ConfigGlobal.appName,
        theme: ThemeData(),
        darkTheme: ThemeData.dark(),
        onGenerateRoute: AppRouter.generateRoute,
        initialRoute: isLogined ? AppRoutes.home : AppRoutes.login,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
