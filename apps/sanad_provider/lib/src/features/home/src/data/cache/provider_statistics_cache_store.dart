import 'package:sanad_provider/src/features/home/src/domain/entities/provider_statistic_entity.dart';

class _CacheEntry {
  const _CacheEntry({required this.items, required this.fetchedAt});

  final List<ProviderStatisticEntity> items;
  final DateTime fetchedAt;
}

/// In-memory, TTL'd cache for the home dashboard statistics, keyed by
/// language (the backend localizes each statistic's `name`, so a locale
/// switch must be a distinct entry — AR must never serve EN labels).
///
/// Mirrors `ActivityLogCacheStore` (the established caching convention).
/// [read] returns the entry even when stale, plus an `isStale` flag, so the
/// bloc can serve cached data immediately and refresh in the background
/// (stale-while-revalidate) rather than blanking the grid on every revisit.
///
/// Registered as a lazy singleton so it survives the bloc being re-created
/// when the user navigates away from and back to Home.
class ProviderStatisticsCacheStore {
  ProviderStatisticsCacheStore({this.staleness = const Duration(seconds: 60)});

  final Duration staleness;
  final Map<String, _CacheEntry> _entries = {};

  static String keyFor({required String languageCode}) => languageCode;

  ({List<ProviderStatisticEntity> items, bool isStale})? read(String key) {
    final entry = _entries[key];
    if (entry == null) return null;
    final isStale = DateTime.now().difference(entry.fetchedAt) >= staleness;
    return (items: entry.items, isStale: isStale);
  }

  void write(String key, List<ProviderStatisticEntity> items) {
    _entries[key] = _CacheEntry(items: items, fetchedAt: DateTime.now());
  }

  /// Drops all cached statistics — used when an action elsewhere is known to
  /// have changed the underlying counts.
  void invalidate() => _entries.clear();
}
