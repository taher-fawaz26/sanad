import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:network/src/interceptors/logging_interceptor.dart';

void main() {
  group('LoggingInterceptor.isSensitivePath', () {
    test('flags common auth surfaces', () {
      const paths = [
        '/auth/login',
        '/AUTH/refresh',
        '/api/v1/otp/verify',
        '/user/password/reset',
        '/verify-phone',
        '/oauth/token',
      ];
      for (final path in paths) {
        expect(
          LoggingInterceptor.isSensitivePath(path),
          isTrue,
          reason: 'expected $path to be sensitive',
        );
      }
    });

    test('leaves normal paths alone', () {
      const paths = [
        '/workers',
        '/branches/br_1',
        '/services',
        '/profile',
      ];
      for (final path in paths) {
        expect(
          LoggingInterceptor.isSensitivePath(path),
          isFalse,
          reason: 'expected $path to be non-sensitive',
        );
      }
    });
  });

  group('LoggingInterceptor.preview', () {
    test('replaces entire body on sensitive path', () {
      final out = LoggingInterceptor.preview(
        {'email': 'a@b.c', 'password': 'hunter2'},
        sensitive: true,
      );
      expect(out, LoggingInterceptor.redactedMarker);
      expect(out.contains('hunter2'), isFalse);
      expect(out.contains('a@b.c'), isFalse);
    });

    test('redacts sensitive keys on non-sensitive path', () {
      final out = LoggingInterceptor.preview(
        {'name': 'Ada', 'password': 'hunter2', 'refresh_token': 'r-123'},
        sensitive: false,
      );
      final decoded = jsonDecode(out) as Map<String, dynamic>;
      expect(decoded['name'], 'Ada');
      expect(decoded['password'], LoggingInterceptor.redactedMarker);
      expect(decoded['refresh_token'], LoggingInterceptor.redactedMarker);
      expect(out.contains('hunter2'), isFalse);
      expect(out.contains('r-123'), isFalse);
    });

    test('redacts nested sensitive keys inside maps and lists', () {
      final out = LoggingInterceptor.preview(
        {
          'user': {'name': 'Ada', 'apiKey': 'sk-live-abc'},
          'sessions': [
            {'id': '1', 'accessToken': 'at-1'},
            {'id': '2', 'accessToken': 'at-2'},
          ],
        },
        sensitive: false,
      );
      expect(out.contains('sk-live-abc'), isFalse);
      expect(out.contains('at-1'), isFalse);
      expect(out.contains('at-2'), isFalse);
      expect(out.contains('Ada'), isTrue);
    });

    test('key matching is case-insensitive and ignores dashes/underscores', () {
      final out = LoggingInterceptor.preview(
        {
          'PASSWORD': 'p',
          'Refresh-Token': 't',
          'access_token': 'a',
          'API_KEY': 'k',
        },
        sensitive: false,
      );
      expect(out.contains('"p"'), isFalse);
      expect(out.contains('"t"'), isFalse);
      expect(out.contains('"a"'), isFalse);
      expect(out.contains('"k"'), isFalse);
    });

    test('truncates non-sensitive payloads over the limit', () {
      final big = {'blob': 'x' * 1000};
      final out = LoggingInterceptor.preview(big, sensitive: false);
      expect(out.length, lessThan(1000));
      expect(out.contains('chars total'), isTrue);
    });

    test('handles null and primitive payloads', () {
      expect(LoggingInterceptor.preview(null, sensitive: false), 'null');
      expect(LoggingInterceptor.preview(42, sensitive: false), '42');
      expect(
        LoggingInterceptor.preview('hi', sensitive: true),
        LoggingInterceptor.redactedMarker,
      );
    });
  });
}
