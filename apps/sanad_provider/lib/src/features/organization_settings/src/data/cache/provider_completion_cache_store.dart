import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/provider_completion_entity.dart';

class _CacheEntry {
  const _CacheEntry({required this.completion, required this.fetchedAt});

  final ProviderCompletionEntity completion;
  final DateTime fetchedAt;
}

/// In-memory, TTL'd cache for `GET service-provider/completion`, keyed by
/// language (each checklist item's `label` is backend-localized, so a locale
/// switch must be a distinct entry).
///
/// Mirrors `ActivityLogCacheStore` (the established caching convention).
/// [read] returns the entry even when stale, plus an `isStale` flag, so a
/// consumer can serve cached data immediately and refresh in the background.
///
/// Registered as a lazy singleton so it survives the bloc being re-created
/// (Home mounts a fresh `ProviderCompletionBloc`, and the KPI hub another).
class ProviderCompletionCacheStore {
  ProviderCompletionCacheStore({this.staleness = const Duration(seconds: 60)});

  final Duration staleness;
  final Map<String, _CacheEntry> _entries = {};

  static String keyFor({required String languageCode}) => languageCode;

  ({ProviderCompletionEntity completion, bool isStale})? read(String key) {
    final entry = _entries[key];
    if (entry == null) return null;
    final isStale = DateTime.now().difference(entry.fetchedAt) >= staleness;
    return (completion: entry.completion, isStale: isStale);
  }

  void write(String key, ProviderCompletionEntity completion) {
    _entries[key] = _CacheEntry(
      completion: completion,
      fetchedAt: DateTime.now(),
    );
  }

  /// Drops all cached completion snapshots — used after the user returns from
  /// a setup flow that may have changed completion state.
  void invalidate() => _entries.clear();
}
