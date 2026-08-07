import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/page_indicator_tokens.dart';
import 'package:flutter/material.dart';

/// Figma `Controls / Page Controls: Dot` (`40:7639`).
class AppPageIndicator extends StatelessWidget {
  const AppPageIndicator({
    required this.count,
    required this.currentIndex,
    super.key,
  });

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final brightness = Theme.of(context).brightness;
    final spec = PageIndicatorTokens.resolve(
      colors: colors,
      brightness: brightness,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return Padding(
          padding: EdgeInsets.only(
            right: index < count - 1 ? spec.dotSpacing : 0,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: spec.dotSize,
            height: spec.dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? spec.activeColor : spec.inactiveColor,
            ),
          ),
        );
      }),
    );
  }
}
