import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BackendIconResolver.resolve', () {
    test('resolves solid style', () {
      expect(
        BackendIconResolver.resolve('fa-solid fa-store'),
        FontAwesomeIcons.solidStore,
      );
    });

    test('resolves regular style', () {
      expect(
        BackendIconResolver.resolve('fa-regular fa-user'),
        FontAwesomeIcons.user,
      );
    });

    test('resolves light style', () {
      expect(
        BackendIconResolver.resolve('fa-light fa-star'),
        FontAwesomeIcons.lightStar,
      );
    });

    test('resolves thin style', () {
      expect(
        BackendIconResolver.resolve('fa-thin fa-circle'),
        FontAwesomeIcons.thinCircle,
      );
    });

    test('resolves brands style', () {
      expect(
        BackendIconResolver.resolve('fa-brands fa-google'),
        FontAwesomeIcons.google,
      );
    });

    test('resolves sharp + explicit weight', () {
      expect(
        BackendIconResolver.resolve('fa-sharp fa-solid fa-house'),
        FontAwesomeIcons.sharpSolidHouse,
      );
    });

    test('bare fa-sharp defaults to sharp solid', () {
      final withWeight = BackendIconResolver.resolve(
        'fa-sharp fa-solid fa-house',
      );
      final bare = BackendIconResolver.resolve('fa-sharp fa-house');
      expect(bare, withWeight);
    });

    test('resolves legacy short-form style tokens', () {
      expect(
        BackendIconResolver.resolve('fas fa-store'),
        BackendIconResolver.resolve('fa-solid fa-store'),
      );
      expect(
        BackendIconResolver.resolve('fab fa-google'),
        BackendIconResolver.resolve('fa-brands fa-google'),
      );
    });

    test('ignores unrelated classes and order', () {
      expect(
        BackendIconResolver.resolve('some-class fa-solid other fa-tags'),
        BackendIconResolver.resolve('fa-solid fa-tags'),
      );
    });

    test('name without an explicit style defaults to solid', () {
      expect(
        BackendIconResolver.resolve('fa-store'),
        BackendIconResolver.resolve('fa-solid fa-store'),
      );
    });

    test('null input returns null', () {
      expect(BackendIconResolver.resolve(null), isNull);
    });

    test('empty input returns null', () {
      expect(BackendIconResolver.resolve(''), isNull);
      expect(BackendIconResolver.resolve('   '), isNull);
    });

    test('style-only input (no icon name) returns null', () {
      expect(BackendIconResolver.resolve('fa-solid'), isNull);
    });

    test('unknown icon name returns null', () {
      expect(
        BackendIconResolver.resolve('fa-solid fa-this-icon-does-not-exist'),
        isNull,
      );
    });

    test('duotone is unsupported and falls back safely', () {
      expect(BackendIconResolver.resolve('fa-duotone fa-clock'), isNull);
    });

    test('sharp-duotone is unsupported and falls back safely', () {
      expect(
        BackendIconResolver.resolve('fa-sharp fa-duotone fa-clock'),
        isNull,
      );
    });

    test('never throws on malformed input', () {
      expect(BackendIconResolver.resolve('fa-'), isNull);
      expect(
        BackendIconResolver.resolve('   fa-solid   fa-store   '),
        isNotNull,
      );
    });
  });

  group('BackendIconResolver.resolveOrFallback', () {
    test('returns the fallback for an unresolvable string', () {
      expect(
        BackendIconResolver.resolveOrFallback(null),
        FontAwesomeIcons.solidCircleQuestion,
      );
      expect(
        BackendIconResolver.resolveOrFallback('fa-duotone fa-clock'),
        FontAwesomeIcons.solidCircleQuestion,
      );
    });

    test('returns the resolved icon when resolvable', () {
      expect(
        BackendIconResolver.resolveOrFallback('fa-solid fa-store'),
        FontAwesomeIcons.solidStore,
      );
    });
  });

  group('generated mapping coverage (guards style-support claims)', () {
    const representativeCss = [
      'fa-solid fa-store',
      'fa-regular fa-user',
      'fa-light fa-star',
      'fa-thin fa-circle',
      'fa-brands fa-google',
      'fa-sharp fa-solid fa-house',
      'fa-sharp fa-regular fa-house',
      'fa-sharp fa-light fa-house',
      'fa-sharp fa-thin fa-house',
    ];

    for (final css in representativeCss) {
      test('"$css" resolves against the actually generated mapping', () {
        expect(BackendIconResolver.resolve(css), isNotNull, reason: css);
      });
    }
  });
}
