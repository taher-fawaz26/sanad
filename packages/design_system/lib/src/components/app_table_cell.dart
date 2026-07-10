import 'package:design_system/src/theme/tokens/table_tokens.dart';
import 'package:flutter/material.dart';

/// Figma `_Partials / Tables` (`194:3008`) — table/list cell content.
class AppTableCell extends StatelessWidget {
  const AppTableCell({
    required this.title, super.key,
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
          alignment: Alignment.centerLeft,
          child: Text(title, style: spec.titleStyle),
        ),
      );
    }

    return SizedBox(
      height: spec.heightWithCaption,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: spec.titleStyle),
          SizedBox(height: spec.textGap),
          Text(caption!, style: spec.captionStyle),
        ],
      ),
    );
  }
}
