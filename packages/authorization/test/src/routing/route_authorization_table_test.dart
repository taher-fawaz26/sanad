import 'package:authorization/authorization.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const view = PermissionRequirement.single('provider:branch:view');
  const create = PermissionRequirement.single('provider:branch:create');
  const createOrUpdate = PermissionRequirement.any({
    'provider:branch:create',
    'provider:branch:update',
  });

  group('RouteAuthorizationTable.empty', () {
    test('has no rule for any location', () {
      expect(RouteAuthorizationTable.empty.ruleFor('/branches'), isNull);
    });
  });

  group('first-match-wins ordering (Branches shape)', () {
    // Mirrors the real hazard: `^/branches/[^/]+$` also matches
    // `/branches/add` and `/branches/coverage`, so literal rules must be
    // registered ahead of the details pattern.
    final table = RouteAuthorizationTable([
      const RouteRule.exact(
        {'/branches/add'},
        requires: create,
        denyRedirect: '/branches',
      ),
      const RouteRule.exact(
        {'/branches/coverage'},
        requires: createOrUpdate,
        denyRedirect: '/branches',
      ),
      const RouteRule.exact(
        {'/branches'},
        requires: view,
        denyRedirect: '/home',
      ),
      RouteRule.pattern(
        RegExp(r'^/branches/[^/]+$'),
        requires: view,
        denyRedirect: '/home',
      ),
    ]);

    test(
      '/branches/add resolves to the create requirement, not the details pattern',
      () {
        expect(table.ruleFor('/branches/add')!.requires, create);
      },
    );

    test(
      '/branches/coverage resolves to the any(create, update) requirement',
      () {
        expect(table.ruleFor('/branches/coverage')!.requires, createOrUpdate);
      },
    );

    test('/branches resolves to the view requirement', () {
      expect(table.ruleFor('/branches')!.requires, view);
    });

    test('a details id falls through to the pattern rule', () {
      expect(table.ruleFor('/branches/abc-123')!.requires, view);
    });

    test('an unrelated location has no rule', () {
      expect(table.ruleFor('/home'), isNull);
    });
  });

  group('RouteRule matcher kinds', () {
    test('exact matches only the listed paths', () {
      const rule = RouteRule.exact({'/a', '/b'}, requires: view);
      expect(rule.matches('/a'), isTrue);
      expect(rule.matches('/b'), isTrue);
      expect(rule.matches('/c'), isFalse);
    });

    test('prefix matches any location starting with the prefix', () {
      const rule = RouteRule.prefix('/settings', requires: view);
      expect(rule.matches('/settings'), isTrue);
      expect(rule.matches('/settings/general'), isTrue);
      expect(rule.matches('/other'), isFalse);
    });

    test('pattern matches via the supplied RegExp', () {
      final rule = RouteRule.pattern(
        RegExp(r'^/branches/[^/]+$'),
        requires: view,
      );
      expect(rule.matches('/branches/123'), isTrue);
      expect(rule.matches('/branches/123/edit'), isFalse);
    });
  });

  group('denyRedirect', () {
    test('defaults to null, leaving the redirect target to the caller', () {
      const rule = RouteRule.exact({'/x'}, requires: view);
      expect(rule.denyRedirect, isNull);
    });

    test('carries the configured redirect target', () {
      const rule = RouteRule.exact(
        {'/x'},
        requires: view,
        denyRedirect: '/home',
      );
      expect(rule.denyRedirect, '/home');
    });
  });

  group('equality', () {
    test(
      'two exact rules with the same paths/requirement/redirect are equal',
      () {
        expect(
          const RouteRule.exact({'/a'}, requires: view, denyRedirect: '/home'),
          const RouteRule.exact({'/a'}, requires: view, denyRedirect: '/home'),
        );
      },
    );

    test('differing requirement breaks equality', () {
      expect(
        const RouteRule.exact({'/a'}, requires: view),
        isNot(const RouteRule.exact({'/a'}, requires: create)),
      );
    });
  });
}
