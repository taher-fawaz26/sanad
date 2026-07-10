import 'package:design_system/src/dimensions/app_radius.dart';
import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/theme/app_font.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/colors/dark_colors.dart';
import 'package:design_system/src/theme/colors/field_tokens.dart';
import 'package:design_system/src/theme/colors/light_colors.dart';
import 'package:design_system/src/theme/tokens/bottom_nav_tokens.dart';
import 'package:design_system/src/theme/tokens/bottom_sheet_tokens.dart';
import 'package:design_system/src/theme/tokens/button_tokens.dart';
import 'package:design_system/src/theme/tokens/checkbox_tokens.dart';
import 'package:design_system/src/theme/tokens/chip_tokens.dart';
import 'package:design_system/src/theme/tokens/date_picker_tokens.dart';
import 'package:design_system/src/theme/tokens/dialog_tokens.dart';
import 'package:design_system/src/theme/tokens/divider_tokens.dart';
import 'package:design_system/src/theme/tokens/nav_bar_tokens.dart';
import 'package:design_system/src/theme/tokens/radio_tokens.dart';
import 'package:design_system/src/theme/tokens/search_bar_tokens.dart';
import 'package:design_system/src/theme/tokens/segmented_control_tokens.dart';
import 'package:design_system/src/theme/tokens/slider_tokens.dart';
import 'package:design_system/src/theme/tokens/snackbar_tokens.dart';
import 'package:design_system/src/theme/tokens/switch_tokens.dart';
import 'package:design_system/src/theme/tokens/tab_bar_tokens.dart';
import 'package:design_system/src/theme/tokens/table_tokens.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// **Theme composition root.**
///
/// [AppTheme] knows nothing about specific color values or font sizes.
/// It only composes [AppColors] + [AppTypography] into [ThemeData].
///
/// Usage in [MaterialApp]:
/// ```dart
/// theme: AppTheme.light(),
/// darkTheme: AppTheme.dark(),
/// ```
/// Or, when driven by a BLoC (including system brightness):
/// ```dart
/// theme: state.resolvesToDark(context)
///     ? AppTheme.dark()
///     : AppTheme.light(),
/// ```
abstract final class AppTheme {
  AppTheme._();

  static ThemeData light() =>
      _build(brightness: Brightness.light, colors: LightColors.colors);

  static ThemeData dark() =>
      _build(brightness: Brightness.dark, colors: DarkColors.colors);

  // ─── Private composition ─────────────────────────────────────────────────

  static ThemeData _build({
    required Brightness brightness,
    required AppColors colors,
  }) {
    final typography = buildAppTypography();

    // Derive a Material 3 ColorScheme from our semantic tokens.
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: colors.primary,
      onPrimary: colors.onPrimary,
      primaryContainer: colors.surfaceVariant,
      onPrimaryContainer: colors.onSurfaceVariant,
      secondary: colors.secondary,
      onSecondary: colors.onSecondary,
      secondaryContainer: colors.surfaceVariant,
      onSecondaryContainer: colors.onSurfaceVariant,
      tertiary: colors.tertiary,
      onTertiary: colors.onTertiary,
      tertiaryContainer: colors.surface,
      onTertiaryContainer: colors.onSurface,
      error: colors.error,
      onError: colors.onError,
      surface: colors.surface,
      onSurface: colors.onSurface,
      surfaceContainerHighest: colors.surfaceVariant,
      onSurfaceVariant: colors.onSurfaceVariant,
      outline: colors.border,
      outlineVariant: colors.divider,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      // Primary UI font — Poppins (Figma: Dr2_Font_family)
      fontFamily: AppFontFamily.poppins,
      // Fallback chain: NotoSansArabic handles Arabic glyphs automatically
      // when the OS / locale selects Arabic text, without per-widget overrides.
      fontFamilyFallback: const [AppFontFamily.notoSansArabic],

      // ── Extensions (design tokens injected into the theme tree) ─────
      extensions: [
        colors,
        typography,
        SegmentedControlTokens.themeExtension(
          colors: colors,
          typography: typography,
          brightness: brightness,
        ),
        TabBarTokens.themeExtension(
          colors: colors,
          typography: typography,
          brightness: brightness,
        ),
        SearchBarTokens.themeExtension(
          colors: colors,
          typography: typography,
          brightness: brightness,
        ),
        SwitchTokens.themeExtension(
          colors: colors,
          brightness: brightness,
        ),
        DialogTokens.themeExtension(
          colors: colors,
          typography: typography,
          brightness: brightness,
        ),
        SnackbarTokens.themeExtension(
          colors: colors,
          typography: typography,
          brightness: brightness,
        ),
        BottomNavTokens.themeExtension(
          colors: colors,
          typography: typography,
          brightness: brightness,
        ),
        NavBarTokens.themeExtension(
          colors: colors,
          typography: typography,
          brightness: brightness,
        ),
        TableTokens.themeExtension(
          colors: colors,
          typography: typography,
          brightness: brightness,
        ),
      ],

      // ── Component overrides ─────────────────────────────────────────
      appBarTheme: NavBarTokens.appBarTheme(
        colors: colors,
        typography: typography,
        brightness: brightness,
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.secondary,
        foregroundColor: colors.onSecondary,
        elevation: 0, // use shadow token instead of Material elevation
        extendedTextStyle: typography.labelLarge,
      ),

      // ── Card defaults ───────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: colors.surface,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.circularSm,
          side: BorderSide(color: colors.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          elevation: WidgetStateProperty.all(0),
          shadowColor: WidgetStateProperty.all(Colors.transparent),
          surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          splashFactory: NoSplash.splashFactory,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: WidgetStateProperty.all(
            Size(0, responsiveDimension(48)),
          ),
          padding: WidgetStateProperty.all(
            EdgeInsets.symmetric(
              horizontal: responsiveDimension(16),
              vertical: responsiveDimension(8),
            ),
          ),
          textStyle: WidgetStateProperty.all(typography.labelLarge),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimension.radiusPill),
            ),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            return ButtonTokens.resolve(
              type: AppButtonType.primary,
              colors: colors,
              brightness: brightness,
              states: states,
            ).background;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            return ButtonTokens.resolve(
              type: AppButtonType.primary,
              colors: colors,
              brightness: brightness,
              states: states,
            ).foreground;
          }),
        ),
      ),
      tabBarTheme: TabBarTokens.tabBarTheme(
        colors: colors,
        typography: typography,
        brightness: brightness,
      ),
      bottomNavigationBarTheme: BottomNavTokens.bottomNavigationBarTheme(
        colors: colors,
        typography: typography,
        brightness: brightness,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          elevation: WidgetStateProperty.all(0),
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          splashFactory: NoSplash.splashFactory,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: WidgetStateProperty.all(
            Size(0, responsiveDimension(48)),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimension.radiusPill),
            ),
          ),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            return ButtonTokens.resolve(
              type: AppButtonType.outline,
              colors: colors,
              brightness: brightness,
              states: states,
            ).foreground;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            final border = ButtonTokens.resolve(
              type: AppButtonType.outline,
              colors: colors,
              brightness: brightness,
              states: states,
            ).border;
            return BorderSide(
              color: border,
            );
          }),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          splashFactory: NoSplash.splashFactory,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            return ButtonTokens.resolve(
              type: AppButtonType.transparent,
              colors: colors,
              brightness: brightness,
              states: states,
            ).foreground;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            return ButtonTokens.resolve(
              type: AppButtonType.transparent,
              colors: colors,
              brightness: brightness,
              states: states,
            ).background;
          }),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimension.radiusPill),
            ),
          ),
        ),
      ),

      inputDecorationTheme: FieldTokens.inputDecorationTheme(
        colors: colors,
        typography: typography,
        brightness: brightness,
      ),

      chipTheme: ChipTokens.chipTheme(
        colors: colors,
        typography: typography,
        brightness: brightness,
      ),

      checkboxTheme: CheckboxTokens.checkboxTheme(
        colors: colors,
        brightness: brightness,
      ),

      switchTheme: SwitchThemeData(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        thumbColor: WidgetStateProperty.resolveWith((states) {
          final spec = SwitchTokens.resolve(
            colors: colors,
            brightness: brightness,
          );
          final enabled = !states.contains(WidgetState.disabled);
          final selected = states.contains(WidgetState.selected);
          return spec.knobColor(value: selected, enabled: enabled);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          final spec = SwitchTokens.resolve(
            colors: colors,
            brightness: brightness,
          );
          final enabled = !states.contains(WidgetState.disabled);
          final selected = states.contains(WidgetState.selected);
          return spec.trackColor(value: selected, enabled: enabled);
        }),
      ),

      radioTheme: RadioTokens.radioTheme(
        colors: colors,
        brightness: brightness,
      ),

      sliderTheme: SliderTokens.sliderTheme(
        colors: colors,
        brightness: brightness,
      ),

      dividerTheme: DividerTokens.dividerTheme(
        colors: colors,
        brightness: brightness,
      ),

      bottomSheetTheme: BottomSheetTokens.bottomSheetTheme(
        colors: colors,
        typography: typography,
        brightness: brightness,
      ),

      datePickerTheme: DatePickerTokens.datePickerTheme(
        colors: colors,
        typography: typography,
        brightness: brightness,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: EdgeInsets.symmetric(
          horizontal: responsiveDimension(DialogTokens.horizontalInset),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            responsiveDimension(DialogTokens.borderRadius),
          ),
        ),
      ),

      scaffoldBackgroundColor: colors.background,

      textTheme: TextTheme(
        displayLarge: typography.displayLarge,
        displayMedium: typography.displayMedium,
        displaySmall: typography.displaySmall,
        headlineLarge: typography.headlineLarge,
        headlineMedium: typography.headlineMedium,
        headlineSmall: typography.headlineSmall,
        titleLarge: typography.titleLarge,
        titleMedium: typography.titleMedium,
        titleSmall: typography.titleSmall,
        bodyLarge: typography.bodyLarge,
        bodyMedium: typography.bodyMedium,
        bodySmall: typography.bodySmall,
        labelLarge: typography.labelLarge,
        labelMedium: typography.labelMedium,
        labelSmall: typography.labelSmall,
      ).apply(bodyColor: colors.textPrimary, displayColor: colors.textPrimary),

      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
