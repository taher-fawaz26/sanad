import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:network/src/interceptors/logging_interceptor.dart';

void main() {
  group('LoggingInterceptor.preview', () {
    test('encodes map payloads as JSON', () {
      final out = LoggingInterceptor.preview({
        'email': 'a@b.c',
        'password': 'hunter2',
      });
      final decoded = jsonDecode(out) as Map<String, dynamic>;
      expect(decoded['email'], 'a@b.c');
      expect(decoded['password'], 'hunter2');
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
