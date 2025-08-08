import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_auth_service.dart';

class SupabaseWatchlistService {
  SupabaseWatchlistService._();
  static final SupabaseWatchlistService instance = SupabaseWatchlistService._();

  SupabaseClient get _client => SupabaseAuthService.instance.client;

  String? get _userId => SupabaseAuthService.instance.currentUser?.id;

  bool get isSignedIn => _userId != null;

  Future<List<String>> fetchWatchlist() async {
    final uid = _userId;
    if (uid == null) return [];
    final res = await _client
        .from('watchlist')
        .select('symbol')
        .eq('user_id', uid)
        .eq('is_active', true)
        .order('added_at', ascending: true);
    // res is List<dynamic> of maps
    return (res as List)
        .map((row) => (row as Map<String, dynamic>)['symbol'] as String)
        .toList();
  }

  Future<void> addSymbol(String symbol) async {
    final uid = _userId;
    if (uid == null) return;
    await _client.from('watchlist').upsert(
      {
        'user_id': uid,
        'symbol': symbol.toUpperCase(),
        'is_active': true,
        'added_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id,symbol',
    );
  }

  Future<void> addSymbolsBulk(List<String> symbols) async {
    final uid = _userId;
    if (uid == null || symbols.isEmpty) return;
    final rows = symbols
        .map((s) => {
              'user_id': uid,
              'symbol': s.toUpperCase(),
              'is_active': true,
              'added_at': DateTime.now().toIso8601String(),
            })
        .toList();
    await _client.from('watchlist').upsert(rows, onConflict: 'user_id,symbol');
  }

  Future<void> removeSymbol(String symbol) async {
    final uid = _userId;
    if (uid == null) return;
  await _client
    .from('watchlist')
    .delete()
    .eq('user_id', uid)
    .eq('symbol', symbol.toUpperCase());
  }

  Future<void> clearAll() async {
    final uid = _userId;
    if (uid == null) return;
    await _client
        .from('watchlist')
        .update({'is_active': false})
        .eq('user_id', uid)
        .eq('is_active', true);
  }
}
