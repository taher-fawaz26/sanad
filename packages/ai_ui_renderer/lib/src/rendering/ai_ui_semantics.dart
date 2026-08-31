import 'package:flutter/widgets.dart';

/// Applies a node's `a11yLabel` to a **leaf** node.
///
/// A bare `Semantics(label: …)` around a `Text` *merges* the two labels, so a
/// screen reader would announce `"Phone number\n+971501234567"` — the raw
/// digits are exactly what the label was meant to replace. Leaves therefore
/// exclude their child's semantics, which makes `a11yLabel` a genuine
/// override.
///
/// Containers deliberately do **not** use this: a card's label should describe
/// the group while its children stay individually reachable. Excluding there
/// would make the contents invisible to assistive tech.
Widget leafSemantics({
  required Widget child,
  String? label,
  bool image = false,
}) {
  if (label == null || label.isEmpty) {
    return image ? Semantics(image: true, child: child) : child;
  }
  return Semantics(
    label: label,
    image: image,
    excludeSemantics: true,
    child: child,
  );
}
