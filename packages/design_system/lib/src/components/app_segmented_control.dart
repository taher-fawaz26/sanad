import 'package:app_animations/app_animations.dart';
import 'package:design_system/src/theme/tokens/segmented_control_tokens.dart';
import 'package:flutter/material.dart';

/// One segment of an [AppSegmentedControl].
///
/// [value] is the identity compared against the control's `selectedValue` —
/// it does not have to be an index; callers can key segments by an enum, a
/// route id, or any other domain value.
@immutable
class AppSegmentedControlItem<T> {
  const AppSegmentedControlItem({
    required this.value,
    required this.label,
    this.enabled = true,
    this.semanticsLabel,
  });

  final T value;
  final String label;

  /// When `false`, the segment ignores taps and renders with a muted style.
  final bool enabled;

  /// Overrides the accessibility label; defaults to [label].
  final String? semanticsLabel;
}

/// Pill-style multi-segment tab control — Figma `Tab (5 Tabs)`
/// (`5579:26572`, `5579:25923`).
///
/// UI-only: the number of segments comes entirely from [items], and the
/// widget owns no business logic — selection and any resulting navigation or
/// data fetching are the caller's responsibility via [onChanged].
class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({
    required this.items,
    required this.selectedValue,
    required this.onChanged,
    super.key,
    this.showError = false,
  });

  final List<AppSegmentedControlItem<T>> items;
  final T selectedValue;
  final ValueChanged<T> onChanged;
  final bool showError;

  @override
  Widget build(BuildContext context) {
    final spec = context.segmentedControlSpec(showError: showError);
    final selectedIndex = items.indexWhere((i) => i.value == selectedValue);

    return Container(
      padding: spec.trackPadding,
      decoration: spec.trackDecoration,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / items.length;
          final isRtl = Directionality.of(context) == TextDirection.rtl;
          final visualIndex = isRtl
              ? items.length - 1 - selectedIndex
              : selectedIndex;

          return Stack(
            children: [
              if (selectedIndex >= 0)
                AnimatedPositioned(
                  duration: AppMotionDuration.quick,
                  curve: AppMotionCurve.standard,
                  left: segmentWidth * visualIndex,
                  top: 0,
                  bottom: 0,
                  width: segmentWidth,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: spec.selectedBackground,
                      borderRadius: spec.itemRadius,
                      boxShadow: spec.selectedShadow,
                    ),
                  ),
                ),
              Row(
                children: [
                  for (final item in items)
                    Expanded(
                      child: _Segment<T>(
                        item: item,
                        selected: item.value == selectedValue,
                        spec: spec,
                        onTap: item.enabled
                            ? () => onChanged(item.value)
                            : null,
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.item,
    required this.selected,
    required this.spec,
    required this.onTap,
  });

  final AppSegmentedControlItem<T> item;
  final bool selected;
  final SegmentedControlStyleSpec spec;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final style = !item.enabled
        ? spec.disabledLabelStyle
        : selected
        ? spec.selectedLabelStyle
        : spec.unselectedLabelStyle;

    return Semantics(
      container: true,
      button: true,
      enabled: item.enabled,
      selected: selected,
      label: item.semanticsLabel ?? item.label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: spec.itemHeight,
          child: Center(
            child: ExcludeSemantics(
              child: Text(
                item.label,
                style: style,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
