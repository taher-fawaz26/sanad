import 'package:storage/storage.dart';

/// Remembers which notifications have already been acted on.
///
/// The same underlying event can reach a device more than once — a foreground
/// push and then the tap that reopens the app, or a push and the inbox row for
/// the same notification. Navigating twice for one event is the visible bug
/// this prevents.
///
/// Keyed on the **stable server notification id** only. Timestamps and locally
/// generated ids are not stable across channels and are never used.
///
/// Persisted, because the two deliveries can straddle a process death: a push
/// handled in the background and the cold-start tap that follows it are
/// different app runs.
class NotificationDedupStore {
  NotificationDedupStore({
    required LocalStorage storage,
    this.capacity = 200,
  }) : _storage = storage;

  static const String _storageKey = 'notification_handled_ids';

  final LocalStorage _storage;

  /// How many ids to retain. Bounded so the record cannot grow without limit;
  /// far more than the number of deliveries that can overlap in practice.
  final int capacity;

  List<String>? _cache;

  Future<List<String>> _handled() async {
    final cached = _cache;
    if (cached != null) return cached;
    final raw = await _storage.load(key: _storageKey);
    final loaded = raw is List
        ? raw.map((e) => e.toString()).toList()
        : <String>[];
    return _cache = loaded;
  }

  /// Records [id] and reports whether this is the **first** time it has been
  /// seen — i.e. whether the caller should act on it.
  ///
  /// A `null` or blank id means the delivery carried no stable identity, so it
  /// cannot be deduplicated and is always treated as new. Acting twice is
  /// better than silently dropping a real notification.
  Future<bool> markHandled(String? id) async {
    if (id == null || id.trim().isEmpty) return true;
    final key = id.trim();
    final handled = await _handled();
    if (handled.contains(key)) return false;
    handled.add(key);
    if (handled.length > capacity) {
      handled.removeRange(0, handled.length - capacity);
    }
    await _storage.save(key: _storageKey, value: handled);
    return true;
  }

  /// Whether [id] has already been acted on, without recording it.
  Future<bool> isHandled(String? id) async {
    if (id == null || id.trim().isEmpty) return false;
    return (await _handled()).contains(id.trim());
  }

  /// Forgets everything. Called at a session boundary so one user's handled
  /// ids cannot suppress another's notifications on a shared device.
  Future<void> clear() async {
    _cache = <String>[];
    await _storage.delete(key: _storageKey);
  }
}
