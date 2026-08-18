import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:shared_ui/src/loading/app_skeleton_list.dart';
import 'package:shared_ui/src/loading/app_skeletonizer.dart';

/// Sliver sibling of [SanadPagedList] — use this inside an existing
/// [CustomScrollView] (e.g. alongside a collapsing header built from other
/// slivers) instead of [SanadPagedList], which wraps a [ListView] and cannot
/// be nested inside another scroll view.
///
/// Same builder-delegate contract as [SanadPagedList]: pass a [PagingState]
/// built via `toPagingState` plus a callback that dispatches the feature's
/// own "load next page" event. This widget never touches a BLoC or a
/// `PagingController` itself.
///
/// First-page indicators (loading/error/empty) are shrink-wrapped
/// (`shrinkWrapFirstPageIndicators: true`) rather than expanded to fill the
/// remaining viewport — the caller's own loading/error/empty state is
/// typically already handled a layer up (see `branches_page.dart`'s
/// pattern of checking bloc state before deciding which slivers to include),
/// and shrink-wrapping avoids handing an unbounded-height indicator widget
/// an intrinsic-size query it may not support.
class SanadPagedSliverList<T> extends StatelessWidget {
  const SanadPagedSliverList({
    required this.state,
    required this.fetchNextPage,
    required this.itemBuilder,
    required this.firstPageErrorIndicatorBuilder,
    required this.newPageErrorIndicatorBuilder,
    required this.noItemsFoundIndicatorBuilder,
    super.key,
    this.separatorBuilder,
    this.padding,
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

  /// Applied via [SliverPadding] around the whole sliver — the sliver
  /// equivalent of [SanadPagedList]'s `padding`.
  final EdgeInsetsGeometry? padding;

  /// Defaults to a generic skeleton list ([AppSkeletonList] of bone rows) —
  /// first-page loading has no feature-specific copy, so a default is safe.
  /// Pass a builder that skeletonizes the *real* row for higher fidelity.
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
          firstPageProgressIndicatorBuilder ??
          (_) => AppSkeletonList(
            itemBuilder: (_, _) => const _PagedSliverListSkeletonRow(),
          ),
      newPageProgressIndicatorBuilder:
          newPageProgressIndicatorBuilder ??
          (_) => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: AppLoadingIndicator()),
          ),
    );

    final sliver = separatorBuilder != null
        ? PagedSliverList<int, T>.separated(
            state: state,
            fetchNextPage: fetchNextPage,
            builderDelegate: delegate,
            separatorBuilder: separatorBuilder!,
            shrinkWrapFirstPageIndicators: true,
          )
        : PagedSliverList<int, T>(
            state: state,
            fetchNextPage: fetchNextPage,
            builderDelegate: delegate,
            shrinkWrapFirstPageIndicators: true,
          );

    final p = padding;
    return p == null ? sliver : SliverPadding(padding: p, sliver: sliver);
  }
}

/// Generic list-item skeleton (avatar + two text bars) used as the default
/// first-page placeholder when a caller doesn't skeletonize its own row.
/// Mirrors `SanadPagedList`'s private `_PagedListSkeletonRow`.
class _PagedSliverListSkeletonRow extends StatelessWidget {
  const _PagedSliverListSkeletonRow();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.all(12),
      child: const Row(
        spacing: 12,
        children: [
          Bone.circle(size: 40),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                Bone.text(words: 2),
                Bone.text(words: 1, fontSize: 12),
              ],
            ),
          ),
          Bone(width: 50, height: 20),
        ],
      ),
    );
  }
}
