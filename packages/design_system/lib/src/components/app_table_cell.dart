import 'package:design_system/src/theme/tokens/table_tokens.dart';
import 'package:flutter/material.dart';

/// Figma `_Partials / Tables` (`40:8360`) — title ± caption text block.
class AppTableCell extends StatelessWidget {
  const AppTableCell({
    required this.title,
    super.key,
    this.caption,
  });

  final String title;
  final String? caption;

  bool get _hasCaption => caption != null && caption!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final spec = context.appTableTheme.cell;

    if (!_hasCaption) {
      return SizedBox(
        height: spec.height,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            title,
            style: spec.titleStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    return SizedBox(
      height: spec.height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: spec.titleStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: spec.textGap),
          Text(
            caption!,
            style: spec.captionStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
