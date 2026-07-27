import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network/src/ssl/certificate_pinner.dart';
import 'package:network/src/ssl/pinned_http_client_adapter.dart';

void main() {
  group('CertificatePinner.check', () {
    test('accepts every certificate when enforcement is disabled', () {
      const p = CertificatePinner(pinsByHost: {}, enforce: false);
      expect(p.check(_FakeCert(_derA), 'api.example.com'), isTrue);
    });

    test('accepts a certificate whose SHA-256 is in the pin set', () {
      final p = CertificatePinner(
        pinsByHost: {
          'api.example.com': {_fp(_derA)},
        },
        enforce: true,
      );
      expect(p.check(_FakeCert(_derA), 'api.example.com'), isTrue);
    });

    test('rejects a certificate whose SHA-256 is not in the pin set', () {
      final p = CertificatePinner(
        pinsByHost: {
          'api.example.com': {_fp(_derA)},
        },
        enforce: true,
      );
      expect(p.check(_FakeCert(_derB), 'api.example.com'), isFalse);
    });

    test('rejects a certificate for a host with no configured pins '
        '(fail-closed)', () {
      const p = CertificatePinner(pinsByHost: {}, enforce: true);
      expect(p.check(_FakeCert(_derA), 'api.example.com'), isFalse);
    });

    test('host match is case-insensitive', () {
      final p = CertificatePinner(
        pinsByHost: {
          'api.example.com': {_fp(_derA)},
        },
        enforce: true,
      );
      expect(p.check(_FakeCert(_derA), 'API.Example.COM'), isTrue);
    });

    test('empty pin-set for a host still rejects under enforcement', () {
      const p = CertificatePinner(
        pinsByHost: {'api.example.com': <String>{}},
        enforce: true,
      );
      expect(p.check(_FakeCert(_derA), 'api.example.com'), isFalse);
    });

    test('hasAnyPin reflects whether the map has at least one non-empty entry',
        () {
      expect(
        const CertificatePinner(pinsByHost: {}, enforce: true).hasAnyPin,
        isFalse,
      );
      expect(
        const CertificatePinner(
          pinsByHost: {'a.example.com': <String>{}},
          enforce: true,
        ).hasAnyPin,
        isFalse,
      );
      expect(
        CertificatePinner(
          pinsByHost: {
            'a.example.com': {_fp(_derA)},
          },
          enforce: true,
        ).hasAnyPin,
        isTrue,
      );
    });
  });

  group('parsePinnerSpec', () {
    test('empty spec yields an empty pin map', () {
      final p = parsePinnerSpec('', enforce: true);
      expect(p.pinsByHost, isEmpty);
      expect(p.enforce, isTrue);
    });

    test('parses a single host with a single pin', () {
      final p = parsePinnerSpec(
        'api.example.com=abc123==',
        enforce: true,
      );
      expect(p.pinsByHost, {
        'api.example.com': {'abc123=='},
      });
    });

    test('parses multiple hosts with multiple pins each', () {
      final p = parsePinnerSpec(
        'api.example.com=pinA,pinB; staging.example.com=pinC',
        enforce: true,
      );
      expect(p.pinsByHost, {
        'api.example.com': {'pinA', 'pinB'},
        'staging.example.com': {'pinC'},
      });
    });

    test('lowercases hosts and strips whitespace', () {
      final p = parsePinnerSpec(
        '  API.Example.COM  =  pinA , pinB  ',
        enforce: true,
      );
      expect(p.pinsByHost, {
        'api.example.com': {'pinA', 'pinB'},
      });
    });

    test('throws on malformed entries', () {
      expect(
        () => parsePinnerSpec('no-equals-sign', enforce: true),
        throwsArgumentError,
      );
      expect(
        () => parsePinnerSpec('=leading-empty-host', enforce: true),
        throwsArgumentError,
      );
    });
  });

  group('CertificatePinner.fingerprintOf', () {
    test('matches the base64(sha256(der)) reference', () {
      final cert = _FakeCert(_derA);
      final expected = base64.encode(sha256.convert(_derA).bytes);
      expect(CertificatePinner.fingerprintOf(cert), expected);
    });
  });
}

// ─── Fixtures ─────────────────────────────────────────────────────────────

final Uint8List _derA = Uint8List.fromList(
  List<int>.generate(64, (i) => i),
);
final Uint8List _derB = Uint8List.fromList(
  List<int>.generate(64, (i) => 255 - i),
);

String _fp(Uint8List der) => base64.encode(sha256.convert(der).bytes);

class _FakeCert implements X509Certificate {
  _FakeCert(this._der);
  final Uint8List _der;

  @override
  Uint8List get der => _der;

  @override
  String get pem => throw UnimplementedError();

  @override
  Uint8List get sha1 => throw UnimplementedError();

  @override
  String get subject => 'CN=test';

  @override
  String get issuer => 'CN=test-issuer';

  @override
  DateTime get startValidity => DateTime(2025);

  @override
  DateTime get endValidity => DateTime(2035);
}
