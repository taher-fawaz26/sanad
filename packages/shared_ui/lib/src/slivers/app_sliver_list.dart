import 'package:flutter/material.dart';

/// Declarative [SliverList] wrapper built on [SliverChildBuilderDelegate].
///
/// Pass [separatorBuilder] to interleave separators between items (the item
/// count reported to the delegate accounts for the separators automatically).
class AppSliverList extends StatelessWidget {
  const AppSliverList.builder({
    required this.itemBuilder,
    required this.itemCount,
    super.key,
    this.separatorBuilder,
  });

  final IndexedWidgetBuilder itemBuilder;
  final int itemCount;
  final IndexedWidgetBuilder? separatorBuilder;

  @override
  Widget build(BuildContext context) {
    final separator = separatorBuilder;
    if (separator == null) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          itemBuilder,
          childCount: itemCount,
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index.isOdd) {
            return separator(context, index ~/ 2);
          }
          return itemBuilder(context, index ~/ 2);
        },
        childCount: itemCount == 0 ? 0 : itemCount * 2 - 1,
      ),
    );
  }
}
