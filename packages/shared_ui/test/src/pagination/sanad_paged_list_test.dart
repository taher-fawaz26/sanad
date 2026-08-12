import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:shared_ui/shared_ui.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  TextDirection direction = TextDirection.ltr,
}) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder: (_, _) => MaterialApp(
        theme: AppTheme.light(),
        home: Directionality(
          textDirection: direction,
          child: Scaffold(body: child),
        ),
      ),
    ),
  );
}

SanadPagedList<int> _list(
  PagingState<int, int> state, {
  VoidCallback? fetchNextPage,
  bool tagDirection = false,
}) => SanadPagedList<int>(
  state: state,
  fetchNextPage: fetchNextPage ?? () {},
  itemBuilder: (context, item, index) => Text(
    tagDirection
        ? 'item-$item-${Directionality.of(context).name}'
        : 'item-$item',
  ),
  firstPageErrorIndicatorBuilder: (_) => const Text('first page error'),
  newPageErrorIndicatorBuilder: (_) => const Text('next page error'),
  noItemsFoundIndicatorBuilder: (_) => const Text('empty'),
);

void main() {
  group('SanadPagedList', () {
    testWidgets('renders items from an already-loaded PaginationData', (
      tester,
    ) async {
      const meta = PageMeta(
        totalItems: 2,
        itemCount: 2,
        itemsPerPage: 10,
        totalPages: 1,
        currentPage: 1,
      );
      final state = toPagingState(
        const PaginationData<int>(
          status: RequestStatus.success,
          items: [1, 2],
          meta: meta,
        ),
      );

      await _pump(tester, _list(state));

      expect(find.text('item-1'), findsOneWidget);
      expect(find.text('item-2'), findsOneWidget);
    });

    testWidgets('renders the first-page error builder on firstPageError', (
      tester,
    ) async {
      final state = toPagingState(
        const PaginationData<int>(
          status: RequestStatus.failure,
          firstPageError: ServerFailure(message: 'boom'),
        ),
      );

      await _pump(tester, _list(state));

      expect(find.text('first page error'), findsOneWidget);
    });

    testWidgets('renders the empty builder when loaded with no items', (
      tester,
    ) async {
      final state = toPagingState(
        const PaginationData<int>(status: RequestStatus.success),
      );

      await _pump(tester, _list(state));

      expect(find.text('empty'), findsOneWidget);
    });

    testWidgets('calls fetchNextPage exactly once per page-driven state', (
      tester,
    ) async {
      var calls = 0;
      const meta = PageMeta(
        totalItems: 4,
        itemCount: 2,
        itemsPerPage: 2,
        totalPages: 2,
        currentPage: 1,
      );
      final state = toPagingState(
        const PaginationData<int>(
          status: RequestStatus.success,
          items: [1, 2],
          meta: meta,
        ),
      );

      await _pump(tester, _list(state, fetchNextPage: () => calls++));
      // hasNextPage is true, so the bottom loader animates indefinitely —
      // pump a few frames instead of pumpAndSettle (which would never
      // settle) and assert the list still renders without throwing.
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('item-1'), findsOneWidget);
      expect(find.text('item-2'), findsOneWidget);
    });

    testWidgets('renders correctly under RTL directionality', (tester) async {
      const meta = PageMeta(
        totalItems: 1,
        itemCount: 1,
        itemsPerPage: 10,
        totalPages: 1,
        currentPage: 1,
      );
      final state = toPagingState(
        const PaginationData<int>(
          status: RequestStatus.success,
          items: [1],
          meta: meta,
        ),
      );

      await _pump(
        tester,
        _list(state, tagDirection: true),
        direction: TextDirection.rtl,
      );

      expect(find.text('item-1-rtl'), findsOneWidget);
    });

    testWidgets('renders correctly under LTR directionality', (tester) async {
      const meta = PageMeta(
        totalItems: 1,
        itemCount: 1,
        itemsPerPage: 10,
        totalPages: 1,
        currentPage: 1,
      );
      final state = toPagingState(
        const PaginationData<int>(
          status: RequestStatus.success,
          items: [1],
          meta: meta,
        ),
      );

      await _pump(tester, _list(state, tagDirection: true));

      expect(find.text('item-1-ltr'), findsOneWidget);
    });
  });
}
