import 'package:hive_ce/hive.dart';

import 'package:storage/src/constants/hive_boxes.dart';
import 'package:storage/src/hive/hive_encryption_key_manager.dart';
import 'package:storage/src/hive/local_storage.dart';

class HiveLocalStorage implements LocalStorage {
  HiveLocalStorage({required this.encryptionKeyManager});

  final HiveEncryptionKeyManager encryptionKeyManager;

  /// In-flight box opens are deduped so concurrent callers share one future.
  final Map<String, Future<Box<dynamic>>> _openInFlight = {};

  Future<Box<dynamic>> _openBox(String name) {
    if (Hive.isBoxOpen(name)) return Future.value(Hive.box(name));
    final pending = _openInFlight[name];
    if (pending != null) return pending;
    final future = _openBoxImpl(name);
    _openInFlight[name] = future;
    return future.whenComplete(() => _openInFlight.remove(name));
  }

  Future<Box<dynamic>> _openBoxImpl(String name) async {
    final cipher = await encryptionKeyManager.getEncryptionCipher(name);
    return Hive.openBox(name, encryptionCipher: cipher);
  }

  @override
  Future<Object?> load({required String key, String? boxName}) async {
    final box = await _openBox(boxName ?? HiveBoxes.defaultBox);
    return box.get(key);
  }

  @override
  Future<void> save({
    required String key,
    required Object? value,
    String? boxName,
  }) async {
    final box = await _openBox(boxName ?? HiveBoxes.defaultBox);
    await box.put(key, value);
  }

  @override
  Future<void> delete({required String key, String? boxName}) async {
    final box = await _openBox(boxName ?? HiveBoxes.defaultBox);
    await box.delete(key);
  }
}
