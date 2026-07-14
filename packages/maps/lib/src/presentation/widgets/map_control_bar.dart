import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class MapControlBar extends StatelessWidget {
  const MapControlBar({
    required this.children,
    this.alignment = Alignment.topRight,
    this.padding,
    super.key,
  });

  final List<Widget> children;
  final Alignment alignment;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: padding ??
              EdgeInsets.all(AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(height: AppSpacing.xs),
                children[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
