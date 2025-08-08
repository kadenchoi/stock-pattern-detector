import 'package:collection/collection.dart';
import '../managers/settings_manager.dart';
import 'supabase_watchlist_service.dart';
import 'supabase_auth_service.dart';

class WatchlistSyncService {
  WatchlistSyncService._();
  static final WatchlistSyncService instance = WatchlistSyncService._();

  bool _inProgress = false;

  Future<void> syncBidirectional() async {
    if (_inProgress) return;
    if (SupabaseAuthService.instance.currentUser == null) return;
    _inProgress = true;
    try {
      final settings = SettingsManager();
      final local =
          (await settings.getWatchlist()).map((e) => e.toUpperCase()).toList();
      final remote = (await SupabaseWatchlistService.instance.fetchWatchlist())
          .map((e) => e.toUpperCase())
          .toList();

      final localSet = {...local};
      final remoteSet = {...remote};
      final merged = {...localSet, ...remoteSet}.toList()..sort();

      // Push local-only to remote
      final toPush = merged.whereNot(remoteSet.contains).toList();
      if (toPush.isNotEmpty) {
        await SupabaseWatchlistService.instance.addSymbolsBulk(toPush);
      }

      // Update local to merged if different
      if (!const ListEquality<String>().equals(local, merged)) {
        await settings.updateWatchlist(merged);
      }
    } finally {
      _inProgress = false;
    }
  }
}
