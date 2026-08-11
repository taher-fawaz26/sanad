import 'package:branches/src/domain/entities/branch_manager_entity.dart';
import 'package:branches/src/presentation/widgets/branch_manager_picker_field.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const a = BranchManagerEntity(id: 'a', fullName: 'Alice', initials: 'AL');
  const b = BranchManagerEntity(id: 'b', fullName: 'Bob', initials: 'BO');
  const c = BranchManagerEntity(id: 'c', fullName: 'Carol', initials: 'CA');

  group('mergeManagerPages', () {
    test('appends non-duplicate managers from incoming page', () {
      final result = mergeManagerPages([a, b], [c]);
      expect(result, [a, b, c]);
    });

    test('drops managers whose ID already exists in existing list', () {
      final result = mergeManagerPages([a, b], [b, c]);
      expect(result, [a, b, c]);
      expect(result.length, 3);
    });

    test('drops all incoming when all IDs duplicate existing', () {
      final result = mergeManagerPages([a, b], [a, b]);
      expect(result, [a, b]);
    });

    test('returns incoming unchanged when existing is empty', () {
      final result = mergeManagerPages([], [a, b]);
      expect(result, [a, b]);
    });

    test('returns existing unchanged when incoming is empty', () {
      final result = mergeManagerPages([a, b], []);
      expect(result, [a, b]);
    });

    test('preserves order: existing first, then fresh incoming', () {
      final result = mergeManagerPages([c], [a, b, c]);
      expect(result.map((m) => m.id).toList(), ['c', 'a', 'b']);
    });

    test('handles duplicate IDs within incoming itself', () {
      // Two entries with same id in incoming — only the first survives.
      final bDupe = BranchManagerEntity(
        id: 'b',
        fullName: 'Bob Duplicate',
        initials: 'BD',
      );
      final result = mergeManagerPages([a], [b, bDupe, c]);
      expect(result.map((m) => m.id).toList(), ['a', 'b', 'c']);
    });
  });
}
