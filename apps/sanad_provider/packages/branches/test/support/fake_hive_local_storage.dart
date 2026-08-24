import 'package:core/core.dart';
import 'package:mocktail/mocktail.dart';
import 'package:storage/storage.dart';

/// Test-only [HiveLocalStorage] mock — register/unregister around each test
/// via [registerFakeHiveLocalStorage]/[unregisterFakeHiveLocalStorage] so
/// widgets that read `sl<HiveLocalStorage>()` (e.g. the Branches list's
/// swipe-discoverability hint) resolve without a real Hive box.
class MockHiveLocalStorage extends Mock implements HiveLocalStorage {}

/// Registers a [MockHiveLocalStorage] whose `load` resolves to [hintSeen]
/// for any key and whose `save` is a stubbed no-op. Replaces any previous
/// registration. Call [unregisterFakeHiveLocalStorage] in `tearDown`.
MockHiveLocalStorage registerFakeHiveLocalStorage({bool hintSeen = false}) {
  unregisterFakeHiveLocalStorage();
  final storage = MockHiveLocalStorage();
  when(
    () => storage.load(key: any(named: 'key'), boxName: any(named: 'boxName')),
  ).thenAnswer((_) async => hintSeen);
  when(
    () => storage.save(
      key: any(named: 'key'),
      value: any(named: 'value'),
      boxName: any(named: 'boxName'),
    ),
  ).thenAnswer((_) async {});
  sl.registerSingleton<HiveLocalStorage>(storage);
  return storage;
}

void unregisterFakeHiveLocalStorage() {
  if (sl.isRegistered<HiveLocalStorage>()) {
    sl.unregister<HiveLocalStorage>();
  }
}
