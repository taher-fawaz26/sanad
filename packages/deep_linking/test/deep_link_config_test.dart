import 'package:deep_linking/deep_linking.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeepLinkConfig.accepts', () {
    const config = DeepLinkConfig(
      schemes: {'sanadprovider'},
      hosts: {'links.trysanad.us', 'dev-links.trysanad.us'},
    );

    test('accepts a custom-scheme uri regardless of host', () {
      expect(
        config.accepts(Uri.parse('sanadprovider://invitation/abc123')),
        isTrue,
      );
    });

    test('accepts an https uri whose host is allow-listed', () {
      expect(
        config.accepts(
          Uri.parse('https://links.trysanad.us/invitation/abc123'),
        ),
        isTrue,
      );
    });

    test('accepts an http uri whose host is allow-listed', () {
      expect(
        config.accepts(
          Uri.parse('http://dev-links.trysanad.us/invitation/abc123'),
        ),
        isTrue,
      );
    });

    test('rejects an https uri whose host is not allow-listed', () {
      expect(
        config.accepts(Uri.parse('https://evil.example.com/invitation/abc123')),
        isFalse,
      );
    });

    test('rejects an unknown scheme even if the host matches', () {
      expect(
        config.accepts(Uri.parse('ftp://links.trysanad.us/invitation/abc123')),
        isFalse,
      );
    });

    test('an empty config accepts nothing', () {
      const empty = DeepLinkConfig();
      expect(
        empty.accepts(Uri.parse('https://links.trysanad.us/invitation/abc123')),
        isFalse,
      );
      expect(
        empty.accepts(Uri.parse('sanadprovider://invitation/abc123')),
        isFalse,
      );
    });
  });
}
