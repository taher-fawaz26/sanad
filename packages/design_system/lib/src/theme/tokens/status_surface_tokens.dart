import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/alert_tokens.dart';
import 'package:design_system/src/theme/tokens/status_badge_tokens.dart';
import 'package:flutter/material.dart';

/// Shared semantic fill / border / accent colors for inline alerts and outlined
/// status badges — Figma `3821:19134` – `3821:19202`, compliance badges
/// (`3821:19107` – `3821:19192`).
abstract final class StatusSurfaceTokens {
  StatusSurfaceTokens._();

  /// Inline [AppAlert] surfaces.
  static (Color background, Color border, Color accent) alert({
    required AppAlertType type,
    required AppColors colors,
    required Brightness brightness,
  }) {
    return switch (type) {
      AppAlertType.warning => (
          colors.palettes.yellow.shade50,
          colors.warning,
          colors.warning,
        ),
      AppAlertType.error => (
          brightness == Brightness.dark
              ? colors.errorContainer
              : colors.palettes.red.shade50,
          colors.error,
          colors.error,
        ),
      AppAlertType.info => (
          _infoAlertBackground(colors, brightness),
          colors.onInfoContainer,
          colors.onInfoContainer,
        ),
      AppAlertType.rejected => (
          brightness == Brightness.dark
              ? colors.errorContainer
              : colors.palettes.red.shade50,
          colors.palettes.red.shade400,
          colors.palettes.red.shade400,
        ),
    };
  }

  /// Outlined [AppStatusBadge] — same semantic border pairing as [alert].
  static (Color background, Color border, Color foreground) outlinedBadge({
    required AppStatusBadgeType type,
    required AppColors colors,
  }) {
    return switch (type) {
      AppStatusBadgeType.warning => (
          colors.warningContainer,
          colors.warning,
          colors.onWarningContainer,
        ),
      AppStatusBadgeType.alert => (
          colors.errorContainer,
          colors.error,
          colors.onErrorContainer,
        ),
      AppStatusBadgeType.info => (
          colors.infoContainer,
          colors.onInfoContainer,
          colors.onInfoContainer,
        ),
      AppStatusBadgeType.success => (
          colors.successContainer,
          colors.success,
          colors.onSuccessContainer,
        ),
    };
  }

  /// Figma alert Info — Blue/50 (`3821:19180`), lighter than badge fill.
  static Color _infoAlertBackground(AppColors colors, Brightness brightness) {
    if (brightness == Brightness.dark) {
      return colors.infoContainer;
    }
    return Color.alphaBlend(
      colors.infoContainer.withValues(alpha: 0.45),
      colors.surface,
    );
  }
}
