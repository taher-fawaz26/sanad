import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:shared_ui/src/states/app_loading_view.dart';

/// Thin, purely-presentational wrapper around `infinite_scroll_pagination`'s
/// [PagedListView] — the *only* place in the application that imports the
/// package directly. Features pass a [PagingState] built via
/// `toPagingState` (see `paging_state_adapter.dart`) plus a callback that
/// dispatches their own "load next page" event; this widget never touches a
/// BLoC or a `PagingController` itself.
///
/// This is one of several ways to render pagination state — a feature is
/// equally free to build a plain `ListView` over the same
/// `PaginationData<T>` instead. Nothing in the architecture requires this
/// widget.
class SanadPagedList<T> extends StatelessWidget {
  const SanadPagedList({
    required this.state,
    required this.fetchNextPage,
    required this.itemBuilder,
    required this.firstPageErrorIndicatorBuilder,
    required this.newPageErrorIndicatorBuilder,
    required this.noItemsFoundIndicatorBuilder,
    super.key,
    this.separatorBuilder,
    this.padding,
    this.controller,
    this.physics,
    this.shrinkWrap = false,
    this.firstPageProgressIndicatorBuilder,
    this.newPageProgressIndicatorBuilder,
  });

  final PagingState<int, T> state;
  final VoidCallback fetchNextPage;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// Required — error copy is feature/localization-specific, so this
  /// package cannot supply a sensible default.
  final WidgetBuilder firstPageErrorIndicatorBuilder;
  final WidgetBuilder newPageErrorIndicatorBuilder;

  /// Required — empty-state copy is feature-specific.
  final WidgetBuilder noItemsFoundIndicatorBuilder;

  final Widget Function(BuildContext context, int index)? separatorBuilder;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  /// Defaults to [AppLoadingView] — first-page loading has no
  /// feature-specific copy, so a default is safe here.
  final WidgetBuilder? firstPageProgressIndicatorBuilder;

  /// Defaults to a compact bottom loader.
  final WidgetBuilder? newPageProgressIndicatorBuilder;

  @override
  Widget build(BuildContext context) {
    final delegate = PagedChildBuilderDelegate<T>(
      itemBuilder: itemBuilder,
      firstPageErrorIndicatorBuilder: firstPageErrorIndicatorBuilder,
      newPageErrorIndicatorBuilder: newPageErrorIndicatorBuilder,
      noItemsFoundIndicatorBuilder: noItemsFoundIndicatorBuilder,
      firstPageProgressIndicatorBuilder:
          firstPageProgressIndicatorBuilder ?? (_) => const AppLoadingView(),
      newPageProgressIndicatorBuilder:
          newPageProgressIndicatorBuilder ??
          (_) => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: AppLoadingIndicator()),
          ),
    );

    if (separatorBuilder != null) {
      return PagedListView<int, T>.separated(
        state: state,
        fetchNextPage: fetchNextPage,
        builderDelegate: delegate,
        separatorBuilder: separatorBuilder!,
        padding: padding,
        scrollController: controller,
        physics: physics,
        shrinkWrap: shrinkWrap,
      );
    }

    return PagedListView<int, T>(
      state: state,
      fetchNextPage: fetchNextPage,
      builderDelegate: delegate,
      padding: padding,
      scrollController: controller,
      physics: physics,
      shrinkWrap: shrinkWrap,
    );
  }
}
