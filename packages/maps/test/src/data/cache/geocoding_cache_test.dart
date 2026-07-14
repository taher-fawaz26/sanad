import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/data/cache/geocoding_cache.dart';

void main() {
  late GeocodingCache cache;

  setUp(() => cache = GeocodingCache(maxSize: 3));

  group('GeocodingCache', () {
    test('keyFor rounds to 4 decimal places', () {
      const position = LatLng(25.07721234, 55.13961234);
      final key = cache.keyFor(position, 'en');
      expect(key, '25.0772,55.1396|en');
    });

    test('keyFor handles null locale', () {
      const position = LatLng(25.0, 55.0);
      final key = cache.keyFor(position, null);
      expect(key, '25.0000,55.0000|');
    });

    test('put and get round-trip', () {
      cache.put('k1', 'Dubai Marina');
      expect(cache.get('k1'), 'Dubai Marina');
    });

    test('get returns null for missing key', () {
      expect(cache.get('missing'), isNull);
    });

    test('evicts oldest entry when capacity reached', () {
      cache
        ..put('k1', 'v1')
        ..put('k2', 'v2')
        ..put('k3', 'v3')
        ..put('k4', 'v4');

      expect(cache.get('k1'), isNull);
      expect(cache.get('k2'), 'v2');
      expect(cache.length, 3);
    });

    test('accessing an entry promotes it in LRU order', () {
      cache
        ..put('k1', 'v1')
        ..put('k2', 'v2')
        ..put('k3', 'v3');

      cache.get('k1');
      cache.put('k4', 'v4');

      expect(cache.get('k1'), 'v1');
      expect(cache.get('k2'), isNull);
    });

    test('updating existing key does not increase size', () {
      cache
        ..put('k1', 'v1')
        ..put('k1', 'v1-updated');

      expect(cache.length, 1);
      expect(cache.get('k1'), 'v1-updated');
    });

    test('clear removes all entries', () {
      cache
        ..put('k1', 'v1')
        ..put('k2', 'v2')
        ..clear();

      expect(cache.length, 0);
      expect(cache.get('k1'), isNull);
    });
  });
}
