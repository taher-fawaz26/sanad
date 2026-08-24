import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// One selectable value + its already-localized display label for
/// [AppFilterField]. The widget only ever compares [value]s and renders
/// [label]s — it has no notion of what the values mean (a status, a
/// category, a worker type, ...) or which value (if any) represents an
/// "all"/cleared state; that's entirely the caller's choice, typically by
/// including an option whose [value] is `null`.
class AppFilterOption<T> {
  const AppFilterOption({required this.value, required this.label});

  final T value;
  final String label;
}

/// Generic, data-driven filter trigger cell — the bordered, chevron-suffixed
/// button used to open a single-selection filter picker (status, category,
/// type, ...). Resolves [selectedValue] against [options] to show the
/// current selection's label, falling back to [placeholder] when unset or
/// unmatched.
///
/// This renders only the trigger and resolves its label — it does not open
/// a picker itself. Presenting one (typically an `AppActionList` built from
/// the same [options], pushed via `SheetNavigator`) is the caller's
/// responsibility: `sheet_navigation` sits above `shared_ui` in the
/// dependency graph (see `dep_rules.yaml`), so a shared, feature-independent
/// widget cannot push a sheet itself. Wire [onTap] to do that.
class AppFilterField<T> extends StatelessWidget {
  const AppFilterField({
    required this.placeholder,
    required this.options,
    required this.onTap,
    this.selectedValue,
    this.enabled = true,
    super.key,
  });

  /// Shown when [selectedValue] is null or matches no [options] entry.
  final String placeholder;

  final List<AppFilterOption<T>> options;
  final T? selectedValue;
  final VoidCallback? onTap;

  /// `false` renders the cell visually disabled and drops [onTap].
  final bool enabled;

  String get _label {
    for (final option in options) {
      if (option.value == selectedValue) return option.label;
    }
    return placeholder;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final height = responsiveDimension(44);

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDimension.radiusSm),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppDimension.radiusSm),
          child: Container(
            height: height,
            padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimension.radiusSm),
              border: Border.all(color: colors.palettes.sky.shade200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typography
                        .medium(typography.smallTight)
                        .copyWith(color: colors.textPrimary),
                  ),
                ),
                AppSvgPicture.asset(
                  AppSvgs.chevronDown,
                  width: AppDimension.iconMd,
                  height: AppDimension.iconMd,
                  colorFilter: ColorFilter.mode(
                    colors.textSecondary,
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
