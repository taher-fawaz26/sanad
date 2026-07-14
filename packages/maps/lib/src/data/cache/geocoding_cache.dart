import 'package:google_maps_flutter/google_maps_flutter.dart';

/// LRU cache for reverse-geocode results keyed by rounded coordinates.
///
/// Coordinates are rounded to 4 decimal places (~11m precision) to allow
/// nearby lookups to hit the same cache entry.
class GeocodingCache {
  GeocodingCache({this.maxSize = 200});

  final int maxSize;

  final _entries = <String, String>{};
  final _accessOrder = <String>[];

  static const _precision = 4;

  String keyFor(LatLng position, String? locale) {
    final lat = position.latitude.toStringAsFixed(_precision);
    final lng = position.longitude.toStringAsFixed(_precision);
    return '$lat,$lng|${locale ?? ''}';
  }

  String? get(String key) {
    final value = _entries[key];
    if (value != null) {
      _accessOrder
        ..remove(key)
        ..add(key);
    }
    return value;
  }

  void put(String key, String value) {
    if (_entries.containsKey(key)) {
      _accessOrder.remove(key);
    } else if (_entries.length >= maxSize) {
      final evicted = _accessOrder.removeAt(0);
      _entries.remove(evicted);
    }
    _entries[key] = value;
    _accessOrder.add(key);
  }

  void clear() {
    _entries.clear();
    _accessOrder.clear();
  }

  int get length => _entries.length;
}
