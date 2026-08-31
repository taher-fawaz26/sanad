import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiUiUrlPolicy', () {
    test('denyAll rejects everything, including well-formed https', () {
      expect(
        AiUiUrlPolicy.denyAll.isAllowed('https://cdn.trysanad.us/a.png'),
        isFalse,
      );
    });

    group('with an exact-host allowlist', () {
      const policy = AiUiUrlPolicy(allowedHosts: {'cdn.trysanad.us'});

      test('allows the exact host over https', () {
        expect(policy.isAllowed('https://cdn.trysanad.us/a.png'), isTrue);
      });

      test('is case-insensitive on the host', () {
        expect(policy.isAllowed('https://CDN.TrySanad.us/a.png'), isTrue);
      });

      test('rejects a different host', () {
        expect(policy.isAllowed('https://evil.example/a.png'), isFalse);
      });

      test('rejects a subdomain that was not allowlisted', () {
        expect(policy.isAllowed('https://x.cdn.trysanad.us/a.png'), isFalse);
      });

      test('rejects a host that merely ends with the allowed string', () {
        // The classic near-miss: `evilcdn.trysanad.us.attacker.com` and
        // `notcdn.trysanad.us` must not pass an exact-host rule.
        expect(policy.isAllowed('https://notcdn.trysanad.us/a.png'), isFalse);
        expect(
          policy.isAllowed('https://cdn.trysanad.us.attacker.com/a.png'),
          isFalse,
        );
      });
    });

    group('with a suffix allowlist', () {
      const policy = AiUiUrlPolicy(allowedHosts: {'.trysanad.us'});

      test('allows the apex and its subdomains', () {
        expect(policy.isAllowed('https://trysanad.us/a.png'), isTrue);
        expect(policy.isAllowed('https://cdn.trysanad.us/a.png'), isTrue);
        expect(policy.isAllowed('https://a.b.trysanad.us/a.png'), isTrue);
      });

      test('rejects a look-alike parent domain', () {
        expect(policy.isAllowed('https://nottrysanad.us/a.png'), isFalse);
        expect(
          policy.isAllowed('https://trysanad.us.attacker.com/a.png'),
          isFalse,
        );
      });
    });

    group('scheme and authority', () {
      const policy = AiUiUrlPolicy(allowedHosts: {'cdn.trysanad.us'});

      test('rejects non-https schemes', () {
        for (final url in [
          'http://cdn.trysanad.us/a.png',
          'ftp://cdn.trysanad.us/a.png',
          'file:///etc/passwd',
          'data:text/html,<script>alert(1)</script>',
          'javascript:alert(1)',
          'sanad://cdn.trysanad.us/a.png',
        ]) {
          expect(policy.isAllowed(url), isFalse, reason: url);
        }
      });

      test('rejects userinfo used to disguise the real host', () {
        expect(
          policy.isAllowed('https://cdn.trysanad.us@evil.example/a.png'),
          isFalse,
        );
      });

      test('rejects an empty or unparseable URL', () {
        expect(policy.isAllowed(''), isFalse);
        expect(policy.isAllowed('https://'), isFalse);
        expect(policy.isAllowed(':::'), isFalse);
      });

      test('tolerates surrounding whitespace on an otherwise valid URL', () {
        expect(policy.isAllowed('  https://cdn.trysanad.us/a.png '), isTrue);
      });
    });

    test('reject() never echoes the URL back into the reason', () {
      const policy = AiUiUrlPolicy(allowedHosts: {'cdn.trysanad.us'});
      const url = 'https://evil.example/?token=SECRET123';

      final reason = policy.reject(url);

      expect(reason, isNotNull);
      expect(reason, isNot(contains('SECRET123')));
      expect(reason, isNot(contains('evil.example')));
    });
  });
}
