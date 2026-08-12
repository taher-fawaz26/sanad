import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network/network.dart';

class _Item {
  const _Item(this.id, this.name);
  factory _Item.fromJson(Map<String, dynamic> json) =>
      _Item(json['id'] as String, json['name'] as String);
  final String id;
  final String name;
}

void main() {
  group('parsePage', () {
    test('parses the /workers envelope shape', () {
      final json = {
        'data': [
          {'id': 'w1', 'name': 'Ahmed'},
          {'id': 'w2', 'name': 'Sara'},
        ],
        'meta': {
          'totalItems': 12,
          'itemCount': 2,
          'itemsPerPage': 2,
          'totalPages': 6,
          'currentPage': 1,
        },
      };

      final page = parsePage(json, _Item.fromJson);

      expect(page.items, hasLength(2));
      expect(page.items.first.id, 'w1');
      expect(page.meta.totalItems, 12);
      expect(page.meta.currentPage, 1);
      expect(page.hasMore, isTrue);
    });

    test('parses the /provider-services envelope shape identically', () {
      final json = {
        'data': [
          {'id': 's1', 'name': 'Cleaning'},
        ],
        'meta': {
          'totalItems': 1,
          'itemCount': 1,
          'itemsPerPage': 10,
          'totalPages': 1,
          'currentPage': 1,
        },
      };

      final page = parsePage(json, _Item.fromJson);

      expect(page.items, hasLength(1));
      expect(page.hasMore, isFalse);
    });

    test('handles an empty data array', () {
      final json = {
        'data': <Map<String, dynamic>>[],
        'meta': {
          'totalItems': 0,
          'itemCount': 0,
          'itemsPerPage': 10,
          'totalPages': 1,
          'currentPage': 1,
        },
      };

      final page = parsePage(json, _Item.fromJson);

      expect(page.items, isEmpty);
      expect(page.hasMore, isFalse);
    });

    test('falls back to PageMeta.empty() when meta is missing', () {
      final json = {
        'data': [
          {'id': 'w1', 'name': 'Ahmed'},
        ],
      };

      final page = parsePage(json, _Item.fromJson);

      expect(page.items, hasLength(1));
      expect(page.meta, const PageMeta.empty());
    });

    test('falls back to an empty list when data is missing', () {
      final json = {
        'meta': {
          'totalItems': 0,
          'itemCount': 0,
          'itemsPerPage': 10,
          'totalPages': 1,
          'currentPage': 1,
        },
      };

      final page = parsePage(json, _Item.fromJson);

      expect(page.items, isEmpty);
    });
  });
}
