import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

class _Query extends PageQuery {
  const _Query({super.page, super.limit, super.search});

  @override
  PageQuery copyWithPage(int page) =>
      _Query(page: page, limit: limit, search: search);
}

class _FilteredQuery extends PageQuery {
  const _FilteredQuery({super.limit, this.status});

  final String? status;

  @override
  Map<String, dynamic> toQueryMap() => {
    ...super.toQueryMap(),
    if (status != null) 'status': status,
  };

  @override
  PageQuery copyWithPage(int page) =>
      _FilteredQuery(limit: limit, status: status);
}

void main() {
  group('PageQuery limit cap', () {
    test('kMaxPageLimit matches the backend cap', () {
      expect(kMaxPageLimit, 100);
    });

    test('sends the default limit untouched', () {
      expect(const _Query().toQueryMap()['limit'], kDefaultPageLimit);
    });

    test('sends a smaller explicit limit untouched', () {
      expect(const _Query(limit: 10).toQueryMap()['limit'], 10);
    });

    test('sends exactly 100 untouched', () {
      expect(const _Query(limit: 100).toQueryMap()['limit'], 100);
    });

    test('clamps 101 and above to 100 rather than earning a 400', () {
      expect(const _Query(limit: 101).toQueryMap()['limit'], 100);
      expect(const _Query(limit: 5000).toQueryMap()['limit'], 100);
    });

    test('the cap survives a subclass that merges its own filters', () {
      final map = const _FilteredQuery(
        limit: 250,
        status: 'DRAFT',
      ).toQueryMap();
      expect(map['limit'], 100);
      expect(map['status'], 'DRAFT');
    });

    test('leaves the declared limit readable for the caller', () {
      // `limit` is what was asked for; `effectiveLimit` is what goes on the
      // wire. Equatable props still key off the declared value.
      const query = _Query(limit: 250);
      expect(query.limit, 250);
      expect(query.effectiveLimit, 100);
    });
  });
}
