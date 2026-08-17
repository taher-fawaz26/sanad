import 'package:authorization/authorization.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PermissionRequirement.single', () {
    test('satisfied iff the exact action is granted', () {
      const requirement = PermissionRequirement.single(
        'provider:branch:view',
      );
      expect(
        requirement.isSatisfiedBy(
          PermissionSet.from(const ['provider:branch:view']),
        ),
        isTrue,
      );
      expect(
        requirement.isSatisfiedBy(
          PermissionSet.from(const ['provider:branch:update']),
        ),
        isFalse,
      );
    });
  });

  group('PermissionRequirement.any', () {
    test('satisfied if at least one action is granted', () {
      const requirement = PermissionRequirement.any({
        'provider:branch:create',
        'provider:branch:update',
      });
      expect(
        requirement.isSatisfiedBy(
          PermissionSet.from(const ['provider:branch:update']),
        ),
        isTrue,
      );
    });

    test('unsatisfied if none are granted', () {
      const requirement = PermissionRequirement.any({
        'provider:branch:create',
        'provider:branch:update',
      });
      expect(
        requirement.isSatisfiedBy(
          PermissionSet.from(const ['provider:branch:view']),
        ),
        isFalse,
      );
    });

    test('unsatisfied for an empty action set', () {
      const requirement = PermissionRequirement.any({});
      expect(
        requirement.isSatisfiedBy(PermissionSet.from(const ['*'])),
        isFalse,
      );
    });
  });

  group('PermissionRequirement.all', () {
    test('satisfied only if every action is granted', () {
      const requirement = PermissionRequirement.all({
        'provider:branch:view',
        'provider:branch:update',
      });
      expect(
        requirement.isSatisfiedBy(
          PermissionSet.from(const [
            'provider:branch:view',
            'provider:branch:update',
          ]),
        ),
        isTrue,
      );
    });

    test('unsatisfied if any required action is missing', () {
      const requirement = PermissionRequirement.all({
        'provider:branch:view',
        'provider:branch:update',
      });
      expect(
        requirement.isSatisfiedBy(
          PermissionSet.from(const ['provider:branch:view']),
        ),
        isFalse,
      );
    });

    test('satisfied (vacuously) for an empty action set', () {
      const requirement = PermissionRequirement.all({});
      expect(requirement.isSatisfiedBy(PermissionSet.empty), isTrue);
    });
  });

  group('wildcard interop', () {
    test(
      'provider:* satisfies single/any/all requirements built from provider actions',
      () {
        final set = PermissionSet.from(const ['provider:*']);
        expect(
          const PermissionRequirement.single(
            'provider:branch:view',
          ).isSatisfiedBy(set),
          isTrue,
        );
        expect(
          const PermissionRequirement.all({
            'provider:branch:view',
            'provider:worker:view',
          }).isSatisfiedBy(set),
          isTrue,
        );
      },
    );
  });

  group('deny-by-default', () {
    test('an empty PermissionSet fails every non-vacuous requirement', () {
      expect(
        const PermissionRequirement.single(
          'provider:branch:view',
        ).isSatisfiedBy(PermissionSet.empty),
        isFalse,
      );
      expect(
        const PermissionRequirement.any({
          'provider:branch:view',
        }).isSatisfiedBy(PermissionSet.empty),
        isFalse,
      );
    });
  });

  group('equality', () {
    test('same constructor and args are equal', () {
      expect(
        const PermissionRequirement.single('a'),
        const PermissionRequirement.single('a'),
      );
      expect(
        const PermissionRequirement.any({'a', 'b'}),
        const PermissionRequirement.any({'a', 'b'}),
      );
    });

    test(
      'different requirement kinds are not equal even over the same actions',
      () {
        expect(
          const PermissionRequirement.any({'a'}),
          isNot(const PermissionRequirement.all({'a'})),
        );
      },
    );
  });
}
