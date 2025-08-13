import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/platform_database_service.dart';
import 'services/supabase_auth_service.dart';
import 'services/background_task_service.dart';
import 'services/pattern_cache_service.dart';
import 'ui/screens/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Initialize platform-specific database service
  await PlatformDatabaseService.instance.initialize();

  // Initialize Supabase auth
  await SupabaseAuthService.instance.initialize();

  // Initialize caches
  await PatternCacheService.instance.initialize();

  // Configure background tasks (iOS/macOS only - automatically disabled on web)
  await BackgroundTaskService.instance.configure();

  runApp(const FinancialPatternDetectorApp());
}

class FinancialPatternDetectorApp extends StatelessWidget {
  const FinancialPatternDetectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Financial Pattern Detector',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1976D2),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ).data,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1976D2),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ).data,
      ),
      themeMode: ThemeMode.system,
      home: const AuthGate(),
    );
  }
}
