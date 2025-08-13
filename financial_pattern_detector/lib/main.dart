import 'package:financial_pattern_detector/firebase_options.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/platform_database_service.dart';
import 'services/supabase_auth_service.dart';
import 'services/background_task_service.dart';
import 'services/pattern_cache_service.dart';
import 'services/firebase_ai_service.dart';
import 'services/ai_response_cache_service.dart';
import 'ui/screens/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Initialize platform-specific database service
  await PlatformDatabaseService.instance.initialize();

  // Initialize Supabase auth
  await SupabaseAuthService.instance.initialize();

  // Initialize caches
  await PatternCacheService.instance.initialize();
  await AiResponseCacheService.instance.initialize();

  // Configure background tasks (iOS/macOS only - automatically disabled on web)
  await BackgroundTaskService.instance.configure();

  // Firebase appcheck
  await FirebaseAppCheck.instance.activate(
    // You can also use a `ReCaptchaEnterpriseProvider` provider instance as an
    // argument for `webProvider`
    webProvider:
        ReCaptchaV3Provider('16dbb24775fc501e3c8d3b60d676cbe75d14c868'),
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );

  // Initialize Firebase AI service
  await FirebaseAiService.instance.initializeModel();

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
