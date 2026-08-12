import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  group('PaginationData', () {
    test('initial state has no items and is not loading more', () {
      const data = PaginationData<int>();
      expect(data.status, RequestStatus.initial);
      expect(data.items, isEmpty);
      expect(data.isLoadingFirstPage, isFalse);
      expect(data.loadingMore, isFalse);
      expect(data.hasFirstPageError, isFalse);
      expect(data.hasNextPageError, isFalse);
    });

    test('isEmpty is only true after a successful load with no items', () {
      const loading = PaginationData<int>(status: RequestStatus.loading);
      const successEmpty = PaginationData<int>(status: RequestStatus.success);
      const successWithItems = PaginationData<int>(
        status: RequestStatus.success,
        items: [1],
      );
      expect(loading.isEmpty, isFalse);
      expect(successEmpty.isEmpty, isTrue);
      expect(successWithItems.isEmpty, isFalse);
    });

    test('nextPage is meta.currentPage + 1', () {
      const data = PaginationData<int>(
        meta: PageMeta(
          totalItems: 20,
          itemCount: 10,
          itemsPerPage: 10,
          totalPages: 2,
          currentPage: 1,
        ),
      );
      expect(data.nextPage, 2);
    });

    test('copyWith clearFirstPageError clears the error', () {
      const data = PaginationData<int>(
        firstPageError: ServerFailure(message: 'boom'),
      );
      final cleared = data.copyWith(clearFirstPageError: true);
      expect(cleared.firstPageError, isNull);
      expect(cleared.hasFirstPageError, isFalse);
    });

    test('copyWith clearNextPageError clears the error', () {
      const data = PaginationData<int>(
        nextPageError: ServerFailure(message: 'boom'),
      );
      final cleared = data.copyWith(clearNextPageError: true);
      expect(cleared.nextPageError, isNull);
    });

    test('copyWith without clear flags preserves existing errors', () {
      const data = PaginationData<int>(
        firstPageError: ServerFailure(message: 'boom'),
      );
      final updated = data.copyWith(loadingMore: true);
      expect(updated.firstPageError, isNotNull);
      expect(updated.loadingMore, isTrue);
    });
  });
}
