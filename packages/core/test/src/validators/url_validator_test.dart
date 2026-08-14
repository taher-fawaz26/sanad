import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  group('UrlValidator', () {
    group('isValidHttpUrl', () {
      test('accepts http and https URLs', () {
        expect(UrlValidator.isValidHttpUrl('http://example.com'), isTrue);
        expect(UrlValidator.isValidHttpUrl('https://example.com'), isTrue);
      });

      test('rejects URLs with a non-http(s) scheme', () {
        expect(UrlValidator.isValidHttpUrl('ftp://example.com'), isFalse);
        expect(UrlValidator.isValidHttpUrl('mailto:user@example.com'), isFalse);
      });

      test('rejects malformed URLs missing a host', () {
        expect(UrlValidator.isValidHttpUrl('https://'), isFalse);
      });

      test('rejects plain text that is not a URL', () {
        expect(UrlValidator.isValidHttpUrl('not a url'), isFalse);
      });

      test('rejects null and empty', () {
        expect(UrlValidator.isValidHttpUrl(null), isFalse);
        expect(UrlValidator.isValidHttpUrl(''), isFalse);
        expect(UrlValidator.isValidHttpUrl('   '), isFalse);
      });
    });

    group('isValidGoogleMapsUrl', () {
      test('accepts maps.google.<tld> URLs', () {
        expect(
          UrlValidator.isValidGoogleMapsUrl('https://maps.google.com/'),
          isTrue,
        );
      });

      test('accepts www.google.<tld>/maps URLs', () {
        expect(
          UrlValidator.isValidGoogleMapsUrl('https://www.google.com/maps'),
          isTrue,
        );
      });

      test('accepts goo.gl/maps short links', () {
        expect(
          UrlValidator.isValidGoogleMapsUrl('https://goo.gl/maps/abc123'),
          isTrue,
        );
      });

      test('accepts maps.app.goo.gl short links', () {
        expect(
          UrlValidator.isValidGoogleMapsUrl('https://maps.app.goo.gl/abc123'),
          isTrue,
        );
      });

      test('rejects a generic, non-maps URL', () {
        expect(
          UrlValidator.isValidGoogleMapsUrl('https://example.com'),
          isFalse,
        );
      });

      test('rejects null and empty', () {
        expect(UrlValidator.isValidGoogleMapsUrl(null), isFalse);
        expect(UrlValidator.isValidGoogleMapsUrl(''), isFalse);
      });
    });
  });
}
