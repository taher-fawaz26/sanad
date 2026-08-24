import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:network/src/interceptors/logging_interceptor.dart';

void main() {
  group('LoggingInterceptor.preview', () {
    test('encodes map payloads as JSON, redacting sensitive keys', () {
      final out = LoggingInterceptor.preview({
        'email': 'a@b.c',
        'password': 'hunter2',
      });
      final decoded = jsonDecode(out) as Map<String, dynamic>;
      expect(decoded['email'], 'a@b.c');
      expect(decoded['password'], '***');
    });

    test('redacts otp and token values (case-insensitive keys)', () {
      final out = LoggingInterceptor.preview({
        'otp': '123456',
        'accessToken': 'ey.header.sig',
        'RefreshToken': 'r-token',
        'keep': 'me',
      });
      expect(out.contains('123456'), isFalse);
      expect(out.contains('ey.header.sig'), isFalse);
      expect(out.contains('r-token'), isFalse);
      final decoded = jsonDecode(out) as Map<String, dynamic>;
      expect(decoded['otp'], '***');
      expect(decoded['accessToken'], '***');
      expect(decoded['RefreshToken'], '***');
      expect(decoded['keep'], 'me');
    });

    test('redacts sensitive keys nested in maps and lists', () {
      final out = LoggingInterceptor.preview({
        'user': {'otp': '999999', 'name': 'x'},
        'items': [
          {'password': 'p'},
        ],
      });
      expect(out.contains('999999'), isFalse);
      final decoded = jsonDecode(out) as Map<String, dynamic>;
      expect((decoded['user'] as Map)['otp'], '***');
      expect((decoded['user'] as Map)['name'], 'x');
      expect(((decoded['items'] as List)[0] as Map)['password'], '***');
    });

    test('encodes list payloads as JSON', () {
      final out = LoggingInterceptor.preview([
        {'id': 1},
        {'id': 2},
      ]);
      final decoded = jsonDecode(out) as List<dynamic>;
      expect(decoded.length, 2);
      expect((decoded[0] as Map<String, dynamic>)['id'], 1);
    });

    test('truncates large payloads', () {
      final big = {'blob': 'x' * 5000};
      final out = LoggingInterceptor.preview(big);
      expect(out.length, lessThan(5100));
      expect(out.contains('chars total'), isTrue);
    });

    test('handles null and primitive payloads', () {
      expect(LoggingInterceptor.preview(null), 'null');
      expect(LoggingInterceptor.preview(42), '42');
      expect(LoggingInterceptor.preview('hi'), 'hi');
    });
  });
}
