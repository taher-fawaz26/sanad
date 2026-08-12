import 'package:core/core.dart';
import 'package:test/test.dart';

class _TestQuery extends PageQuery {
  const _TestQuery({super.page, super.limit, super.search, this.status});

  final String? status;

  @override
  Map<String, dynamic> toQueryMap() => {
    ...super.toQueryMap(),
    if (status != null) 'status': status,
  };

  @override
  _TestQuery copyWithPage(int page) =>
      _TestQuery(page: page, limit: limit, search: search, status: status);

  @override
  List<Object?> get props => [...super.props, status];
}

void main() {
  group('PageQuery', () {
    test('defaults to page 1 and kDefaultPageLimit', () {
      const query = _TestQuery();
      expect(query.page, 1);
      expect(query.limit, kDefaultPageLimit);
      expect(query.toQueryMap(), {'page': 1, 'limit': kDefaultPageLimit});
    });

    test('omits search when null or blank', () {
      expect(
        const _TestQuery().toQueryMap().containsKey('search'),
        isFalse,
      );
      expect(
        const _TestQuery(search: '   ').toQueryMap().containsKey('search'),
        isFalse,
      );
    });

    test('trims and includes search when non-blank', () {
      const query = _TestQuery(search: '  Mohamed  ');
      expect(query.toQueryMap()['search'], 'Mohamed');
    });

    test('subclass merges its own filters into the query map', () {
      const query = _TestQuery(page: 2, search: 'a', status: 'active');
      expect(query.toQueryMap(), {
        'page': 2,
        'limit': kDefaultPageLimit,
        'search': 'a',
        'status': 'active',
      });
    });

    test('copyWithPage preserves feature-specific fields', () {
      const query = _TestQuery(status: 'active');
      final next = query.copyWithPage(4);
      expect(next.page, 4);
      expect(next.status, 'active');
    });
  });
}
