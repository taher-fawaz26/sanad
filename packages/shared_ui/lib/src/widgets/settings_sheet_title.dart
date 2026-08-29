import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Shared centered title header for Settings bottom sheets — Organization
/// Settings and Account Settings.
///
/// Renders only the title (design-system `title3`, semibold, primary color,
/// centered). It replaces the per-sheet private `_SheetHeader` variants that
/// used to also render a large icon above the title; that icon has been
/// removed by design (SAN-696 follow-up) and is intentionally not accepted
/// as a parameter here — the shared primitive is the single source of truth
/// for the settings-sheet title style.
class SettingsSheetTitle extends StatelessWidget {
  const SettingsSheetTitle({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Text(
      title,
      style: typography.title3.copyWith(
        color: colors.primary,
        fontWeight: FontWeight.w600,
      ),
      textAlign: TextAlign.center,
    );
  }
}
