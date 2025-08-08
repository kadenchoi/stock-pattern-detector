import 'package:flutter/material.dart';
import '../../services/supabase_auth_service.dart';
import '../../services/watchlist_sync_service.dart';
import 'main_screen.dart';
import 'sign_in_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    // Ensure service is initialized
    SupabaseAuthService.instance.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: SupabaseAuthService.instance.onAuthStateChange,
      builder: (context, snapshot) {
        final user = SupabaseAuthService.instance.currentUser;
        if (user == null) {
          return const SignInScreen();
        }
        // Kick off a background sync of the watchlist on sign-in
        WatchlistSyncService.instance.syncBidirectional();
        return const MainScreen();
      },
    );
  }
}
