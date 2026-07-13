/// Persistent key/value storage contract.
///
/// [load] returns `null` when the key is absent.
/// [save] with a `null` value is equivalent to [delete].
abstract class LocalStorage {
  Future<void> save({
    required String key,
    required Object? value,
    String? boxName,
  });

  Future<Object?> load({required String key, String? boxName});

  Future<void> delete({required String key, String? boxName});
}
