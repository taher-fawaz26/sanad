import 'package:deep_linking/deep_linking.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const config = DeepLinkConfig(
    schemes: {'sanadprovider'},
    hosts: {'links.trysanad.us'},
  );

  group('DeepLinkParser.parse', () {
    test('extracts the invitation token from a trusted https link', () {
      final link = DeepLinkParser.parse(
        Uri.parse('https://links.trysanad.us/invitation/abc123'),
        config,
      );

      expect(link, isNotNull);
      expect(link!.location, '/invitation/abc123');
    });

    test(
      'extracts a generic path for a future route unrelated to invitations',
      () {
        final link = DeepLinkParser.parse(
          Uri.parse('https://links.trysanad.us/branch/42'),
          config,
        );

        expect(link, isNotNull);
        expect(link!.location, '/branch/42');
      },
    );

    test('preserves query parameters in the resolved location', () {
      final link = DeepLinkParser.parse(
        Uri.parse('https://links.trysanad.us/invitation/abc123?ref=email'),
        config,
      );

      expect(link!.location, '/invitation/abc123?ref=email');
    });

    test('accepts a trusted custom-scheme link', () {
      final link = DeepLinkParser.parse(
        Uri.parse('sanadprovider://open/invitation/abc123'),
        config,
      );

      expect(link, isNotNull);
      expect(link!.location, '/invitation/abc123');
    });

    test('rejects a link from an untrusted host', () {
      final link = DeepLinkParser.parse(
        Uri.parse('https://evil.example.com/invitation/abc123'),
        config,
      );

      expect(link, isNull);
    });

    test('rejects a link with no path', () {
      final link = DeepLinkParser.parse(
        Uri.parse('https://links.trysanad.us'),
        config,
      );

      expect(link, isNull);
    });

    test('rejects a link whose path is just the root', () {
      final link = DeepLinkParser.parse(
        Uri.parse('https://links.trysanad.us/'),
        config,
      );

      expect(link, isNull);
    });

    test('does not crash on a malformed / unusual uri', () {
      expect(
        () => DeepLinkParser.parse(
          Uri.parse('https://links.trysanad.us/invitation/%%%'),
          config,
        ),
        returnsNormally,
      );
    });
  });
}
