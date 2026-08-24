import 'package:activity_logs/src/domain/entities/activity_log_entry.dart';

class _CacheEntry {
  const _CacheEntry({required this.items, required this.fetchedAt});

  final List<ActivityLogEntry> items;
  final DateTime fetchedAt;
}

/// In-memory, TTL'd cache for "recent activity" slices, keyed by actor +
/// language (the server localizes `name`/`subject.name`, so a locale switch
/// must miss the cache).
///
/// Avoids refetching on every screen visit while staying far short of tight
/// polling — see `WorkerActivityCubit.load`. Registered as a lazy singleton
/// so the cache survives across a section's own bloc being re-created (e.g.
/// navigating away from and back to a worker's details).
class ActivityLogCacheStore {
  ActivityLogCacheStore({this.staleness = const Duration(seconds: 60)});

  final Duration staleness;
  final Map<String, _CacheEntry> _entries = {};

  /// [actorId] is `null` for a global (unfiltered) feed — e.g. the Home
  /// dashboard's Recent Activity preview.
  static String keyFor({
    required String? actorId,
    required String languageCode,
  }) => '${actorId ?? '_global'}|$languageCode';

  List<ActivityLogEntry>? read(String key) {
    final entry = _entries[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.fetchedAt) >= staleness) return null;
    return entry.items;
  }

  void write(String key, List<ActivityLogEntry> items) {
    _entries[key] = _CacheEntry(items: items, fetchedAt: DateTime.now());
  }
}
