import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthService {
  SupabaseAuthService._();
  static final SupabaseAuthService instance = SupabaseAuthService._();

  bool _initialized = false;

  SupabaseClient get client => Supabase.instance.client;

  Future<void> initialize() async {
    if (_initialized) return;
    await dotenv.load(fileName: '.env');
    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];
    if (url == null || anonKey == null) {
      throw StateError('Missing SUPABASE_URL or SUPABASE_ANON_KEY in .env');
    }
    await Supabase.initialize(url: url, anonKey: anonKey);
    _initialized = true;
  }

  Stream<AuthState> get onAuthStateChange => client.auth.onAuthStateChange;

  User? get currentUser => client.auth.currentUser;

  Future<AuthResponse> signInWithEmail(
      {required String email, required String password}) {
    return client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUpWithEmail(
      {required String email, required String password}) {
    return client.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() => client.auth.signOut();
}
