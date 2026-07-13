import 'package:design_system/src/theme/tokens/segmented_control_tokens.dart';
import 'package:flutter/material.dart';

/// Figma `Controls / Segmented Controls` (`40:7332`).
class AppSegmentedControl extends StatelessWidget {
  const AppSegmentedControl({
    required this.segments,
    required this.selectedIndex,
    required this.onChanged,
    super.key,
    this.showError = false,
  });

  final List<String> segments;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final bool showError;

  @override
  Widget build(BuildContext context) {
    final spec = context.segmentedControlSpec(showError: showError);

    return Container(
      height: spec.trackHeight,
      padding: spec.trackPadding,
      decoration: spec.trackDecoration,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / segments.length;
          final textDirection = Directionality.of(context);
          final isRtl = textDirection == TextDirection.rtl;
          final visualIndex = isRtl
              ? segments.length - 1 - selectedIndex
              : selectedIndex;

          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                left: segmentWidth * visualIndex,
                top: 0,
                bottom: 0,
                width: segmentWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: spec.selectedBackground,
                    borderRadius: spec.selectedSegmentRadius,
                    boxShadow: spec.selectedShadow,
                  ),
                ),
              ),
              Row(
                children: List.generate(segments.length, (index) {
                  final selected = index == selectedIndex;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onChanged(index),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Text(
                          segments[index],
                          style: selected
                              ? spec.selectedLabelStyle
                              : spec.unselectedLabelStyle,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}
