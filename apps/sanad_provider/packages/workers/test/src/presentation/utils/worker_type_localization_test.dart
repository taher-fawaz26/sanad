import 'package:flutter_test/flutter_test.dart';
import 'package:workers/src/domain/entities/worker_type.dart';
import 'package:workers/src/presentation/utils/worker_type_localization.dart';

// No EasyLocalization bootstrap — `.tr()` falls back to the raw i18n key,
// matching this package's other presentation tests. Asserting on the key
// (not resolved English/Arabic prose) is what proves the label goes through
// localization at all, rather than a hardcoded string.
void main() {
  group('WorkerTypeLocalizedLabel', () {
    test('manager resolves to the shared system-role key', () {
      expect(
        WorkerType.manager.localizedLabel(),
        'workers.add_worker.type_manager',
      );
    });

    test('worker resolves to the shared system-role key', () {
      expect(
        WorkerType.worker.localizedLabel(),
        'workers.add_worker.type_worker',
      );
    });

    test(
      'both known types resolve to distinct keys (no accidental collision)',
      () {
        expect(
          WorkerType.worker.localizedLabel(),
          isNot(WorkerType.manager.localizedLabel()),
        );
      },
    );
  });
}
