import 'package:flutter/material.dart';

/// Resolves the on-screen [Rect] of the widget registered under [key].
Rect getWidgetGlobalRect(GlobalKey key) {
  assert(key.currentContext != null, 'key is not attached to any widget');
  final renderBox = key.currentContext!.findRenderObject()! as RenderBox;
  final offset = renderBox.localToGlobal(Offset.zero);
  return Rect.fromLTWH(
    offset.dx,
    offset.dy,
    renderBox.size.width,
    renderBox.size.height,
  );
}
