import 'package:authorization/authorization.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PermissionSet.empty', () {
    test('denies everything', () {
      expect(PermissionSet.empty.can('provider:branch:view'), isFalse);
      expect(PermissionSet.empty.can('*'), isFalse);
    });
  });

  group('exact match', () {
    test('grants an action present in the raw list', () {
      final set = PermissionSet.from(const ['provider:branch:view']);
      expect(set.can('provider:branch:view'), isTrue);
    });

    test('denies an action absent from the raw list', () {
      final set = PermissionSet.from(const ['provider:branch:view']);
      expect(set.can('provider:branch:update'), isFalse);
    });

    test('is case-sensitive', () {
      final set = PermissionSet.from(const ['provider:branch:view']);
      expect(set.can('Provider:Branch:View'), isFalse);
    });
  });

  group('bare wildcard "*"', () {
    test('grants any action', () {
      final set = PermissionSet.from(const ['*']);
      expect(set.can('provider:branch:view'), isTrue);
      expect(set.can('anything:at:all'), isTrue);
    });
  });

  group('segment-prefix wildcard', () {
    test(
      'provider:* grants any provider:-prefixed action (observed live shape)',
      () {
        final set = PermissionSet.from(const ['provider:*']);
        expect(set.can('provider:branch:view'), isTrue);
        expect(set.can('provider:worker:create'), isTrue);
      },
    );

    test('provider:* does not grant an unrelated top-level action', () {
      final set = PermissionSet.from(const ['provider:*']);
      expect(set.can('admin:branch:view'), isFalse);
    });

    test(
      'provider:* does not match a same-prefix-different action (providerx:y)',
      () {
        final set = PermissionSet.from(const ['provider:*']);
        expect(set.can('providerx:y'), isFalse);
      },
    );

    test(
      'provider:branch:* grants only branch actions, not sibling resources',
      () {
        final set = PermissionSet.from(const ['provider:branch:*']);
        expect(set.can('provider:branch:view'), isTrue);
        expect(set.can('provider:branch:delete'), isTrue);
        expect(set.can('provider:worker:view'), isFalse);
      },
    );
  });

  group('non-terminal wildcard (unsupported shape)', () {
    test('provider:*:view is dropped, not treated as a grant', () {
      final set = PermissionSet.from(const ['provider:*:view']);
      expect(set.can('provider:branch:view'), isFalse);
      expect(set.can('provider:*:view'), isFalse);
    });
  });

  group('malformed entries', () {
    test('empty string is dropped', () {
      final set = PermissionSet.from(const ['', 'provider:branch:view']);
      expect(set.can('provider:branch:view'), isTrue);
      expect(set.can(''), isFalse);
    });

    test('whitespace-only entry is dropped', () {
      final set = PermissionSet.from(const ['   ', 'provider:branch:view']);
      expect(set.can('provider:branch:view'), isTrue);
    });

    test('a bare "provider" (no colon, no wildcard) is an exact grant only '
        '— it does not act as an implicit prefix', () {
      final set = PermissionSet.from(const ['provider']);
      expect(set.can('provider:branch:view'), isFalse);
      expect(set.can('provider'), isTrue);
    });
  });

  group('blank action lookups', () {
    test('an empty or whitespace-only requested action is always denied', () {
      final set = PermissionSet.from(const ['*']);
      expect(set.can(''), isFalse);
      expect(set.can('   '), isFalse);
    });
  });

  group('canAny', () {
    test('true if at least one action is granted', () {
      final set = PermissionSet.from(const ['provider:branch:view']);
      expect(
        set.canAny(['provider:branch:update', 'provider:branch:view']),
        isTrue,
      );
    });

    test('false if none are granted', () {
      final set = PermissionSet.from(const ['provider:branch:view']);
      expect(
        set.canAny(['provider:branch:update', 'provider:worker:view']),
        isFalse,
      );
    });

    test('false for an empty iterable', () {
      final set = PermissionSet.from(const ['*']);
      expect(set.canAny(<String>[]), isFalse);
    });
  });

  group('canAll', () {
    test('true only if every action is granted', () {
      final set = PermissionSet.from(const [
        'provider:branch:view',
        'provider:branch:update',
      ]);
      expect(
        set.canAll(['provider:branch:view', 'provider:branch:update']),
        isTrue,
      );
    });

    test('false if any action is missing', () {
      final set = PermissionSet.from(const ['provider:branch:view']);
      expect(
        set.canAll(['provider:branch:view', 'provider:branch:update']),
        isFalse,
      );
    });

    test('true for an empty iterable (vacuously satisfied)', () {
      final set = PermissionSet.from(const ['provider:branch:view']);
      expect(set.canAll(<String>[]), isTrue);
    });
  });

  group('deduplicated union shape (matches observed /me.permissions)', () {
    test('a manager-shaped permission list evaluates as expected', () {
      final set = PermissionSet.from(const [
        'provider:branch:view',
        'provider:branch:create',
        'provider:branch:update',
        'provider:worker:view',
        'provider:catalog-service:view',
        'provider:provider-service:view',
      ]);
      expect(set.can('provider:branch:view'), isTrue);
      expect(set.can('provider:branch:delete'), isFalse); // not in the catalog
    });
  });

  group('equality', () {
    test('two sets built from the same raw list are equal', () {
      expect(
        PermissionSet.from(const ['provider:*', 'a']),
        PermissionSet.from(const ['provider:*', 'a']),
      );
    });

    test('sets built from different raw lists are not equal', () {
      expect(
        PermissionSet.from(const ['provider:branch:view']),
        isNot(PermissionSet.from(const ['provider:branch:update'])),
      );
    });
  });
}
