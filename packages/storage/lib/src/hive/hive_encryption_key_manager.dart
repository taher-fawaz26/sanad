import 'dart:convert';

import 'package:core/core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce/hive.dart';
import 'package:storage/src/constants/hive_boxes.dart';

class HiveEncryptionKeyManager {
  HiveEncryptionKeyManager(this._secureStorage);

  final FlutterSecureStorage _secureStorage;
  final Map<String, HiveCipher?> _cipherCache = {};

  static const Set<String> _secureBoxes = {
    HiveBoxes.user,
    HiveBoxes.session,
  };

  Future<HiveCipher?> getEncryptionCipher(String boxName) async {
    if (!_secureBoxes.contains(boxName)) return null;
    if (_cipherCache.containsKey(boxName)) return _cipherCache[boxName];

    final storageKey = StorageKeys.hiveEncryptionKey(boxName);
    final existing = await _secureStorage.read(key: storageKey);

    final List<int> key;
    if (existing == null) {
      key = Hive.generateSecureKey();
      await _secureStorage.write(
        key: storageKey,
        value: base64Encode(key),
      );
    } else {
      key = base64Decode(existing);
    }

    final cipher = HiveAesCipher(key);
    _cipherCache[boxName] = cipher;
    return cipher;
  }
}
