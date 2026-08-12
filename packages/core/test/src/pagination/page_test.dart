import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  group('PageMeta', () {
    test('hasMore is true when currentPage < totalPages', () {
      const meta = PageMeta(
        totalItems: 25,
        itemCount: 10,
        itemsPerPage: 10,
        totalPages: 3,
        currentPage: 1,
      );
      expect(meta.hasMore, isTrue);
    });

    test('hasMore is false on the last page', () {
      const meta = PageMeta(
        totalItems: 25,
        itemCount: 5,
        itemsPerPage: 10,
        totalPages: 3,
        currentPage: 3,
      );
      expect(meta.hasMore, isFalse);
    });

    test('empty() has no more pages', () {
      const meta = PageMeta.empty();
      expect(meta.hasMore, isFalse);
      expect(meta.totalItems, 0);
      expect(meta.currentPage, 1);
      expect(meta.totalPages, 1);
    });

    test('equality is structural', () {
      const a = PageMeta(
        totalItems: 1,
        itemCount: 1,
        itemsPerPage: 10,
        totalPages: 1,
        currentPage: 1,
      );
      const b = PageMeta(
        totalItems: 1,
        itemCount: 1,
        itemsPerPage: 10,
        totalPages: 1,
        currentPage: 1,
      );
      expect(a, equals(b));
    });
  });

  group('Page', () {
    test('hasMore delegates to meta', () {
      const page = Page<int>(
        items: [1, 2],
        meta: PageMeta(
          totalItems: 4,
          itemCount: 2,
          itemsPerPage: 2,
          totalPages: 2,
          currentPage: 1,
        ),
      );
      expect(page.hasMore, isTrue);
    });

    test('empty() has no items and no more pages', () {
      const page = Page<int>.empty();
      expect(page.items, isEmpty);
      expect(page.hasMore, isFalse);
    });

    test('mapItems converts item type while preserving meta', () {
      const meta = PageMeta(
        totalItems: 2,
        itemCount: 2,
        itemsPerPage: 10,
        totalPages: 1,
        currentPage: 1,
      );
      const page = Page<int>(items: [1, 2], meta: meta);

      final mapped = page.mapItems((i) => 'item-$i');

      expect(mapped.items, ['item-1', 'item-2']);
      expect(mapped.meta, meta);
    });
  });
}
