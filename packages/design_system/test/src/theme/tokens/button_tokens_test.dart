import 'package:design_system/src/theme/colors/dark_colors.dart';
import 'package:design_system/src/theme/colors/light_colors.dart';
import 'package:design_system/src/theme/tokens/button_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// `ButtonTokens`' dimension getters scale through `responsiveDimension`,
/// which reads `ScreenUtil()` — pump a bare `ScreenUtilInit` so it's
/// initialized before calling them directly (no widget tree needed beyond
/// that).
Future<void> _initScreenUtil(WidgetTester tester) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      builder: (_, __) => const SizedBox(),
    ),
  );
}

void main() {
  const colors = LightColors.colors;
  const brightness = Brightness.light;

  ButtonSurfaceColors resolve({
    required AppButtonVariant variant,
    AppButtonIntent intent = AppButtonIntent.standard,
    Set<WidgetState> states = const {},
  }) {
    return ButtonTokens.resolve(
      variant: variant,
      intent: intent,
      colors: colors,
      brightness: brightness,
      states: states,
    );
  }

  group('ButtonTokens.resolve — variant x intent orthogonality', () {
    test('every variant x intent combination resolves without throwing', () {
      for (final variant in AppButtonVariant.values) {
        for (final intent in AppButtonIntent.values) {
          for (final states in [
            <WidgetState>{},
            {WidgetState.pressed},
            {WidgetState.disabled},
          ]) {
            expect(
              () => resolve(variant: variant, intent: intent, states: states),
              returnsNormally,
              reason: '$variant x $intent x $states',
            );
          }
        }
      }
    });

    test('primary/standard matches the Figma-verified default surface', () {
      final surface = resolve(variant: AppButtonVariant.primary);
      expect(surface.background, colors.palettes.main.shade600);
      expect(surface.foreground, colors.palettes.dark.shade50);
      expect(surface.hasBorder, isFalse);
    });

    test('primary/standard pressed is a darker shade than default', () {
      final surface = resolve(
        variant: AppButtonVariant.primary,
        states: {WidgetState.pressed},
      );
      expect(surface.background, colors.palettes.main.shade700);
    });

    test('primary/warning uses the yellow ramp, not the main ramp', () {
      final surface = resolve(
        variant: AppButtonVariant.primary,
        intent: AppButtonIntent.warning,
      );
      expect(surface.background, colors.palettes.yellow.shade400);
      expect(surface.background, isNot(colors.palettes.main.shade600));
    });

    test('primary/destructive uses the red ramp', () {
      final surface = resolve(
        variant: AppButtonVariant.primary,
        intent: AppButtonIntent.destructive,
      );
      expect(surface.background, colors.palettes.red.shade600);
    });

    test(
      'outline/destructive is reachable — was unreachable via the old '
      'AppButton(destructive: bool) API, which only ever rendered filled',
      () {
        final surface = resolve(
          variant: AppButtonVariant.outline,
          intent: AppButtonIntent.destructive,
        );
        expect(surface.background, Colors.transparent);
        expect(surface.foreground, colors.palettes.red.shade600);
        expect(surface.border, colors.palettes.red.shade600);
      },
    );

    test('secondary is a tonal surface — light background, colored text', () {
      final surface = resolve(variant: AppButtonVariant.secondary);
      expect(surface.background, colors.palettes.main.shade50);
      expect(surface.foreground, colors.palettes.main.shade600);
    });

    test('outline is a bordered, transparent-fill surface', () {
      final surface = resolve(variant: AppButtonVariant.outline);
      expect(surface.background, Colors.transparent);
      expect(surface.hasBorder, isTrue);
      expect(surface.border, colors.palettes.main.shade600);
    });

    test('transparent has no fill and no border', () {
      final surface = resolve(variant: AppButtonVariant.transparent);
      expect(surface.background, Colors.transparent);
      expect(surface.hasBorder, isFalse);
    });
  });

  group('ButtonTokens.resolve — disabled state', () {
    test(
      'standard and destructive share the same neutral disabled surface '
      '(Figma confirms Primary/Disabled and Secondary/Disabled are '
      'pixel-identical — disabled must not vary by intent for these two)',
      () {
        final standard = resolve(
          variant: AppButtonVariant.primary,
          states: {WidgetState.disabled},
        );
        final destructive = resolve(
          variant: AppButtonVariant.primary,
          intent: AppButtonIntent.destructive,
          states: {WidgetState.disabled},
        );
        expect(standard.background, destructive.background);
        expect(standard.foreground, destructive.foreground);
      },
    );

    test('primary and secondary share the same disabled surface', () {
      final primary = resolve(
        variant: AppButtonVariant.primary,
        states: {WidgetState.disabled},
      );
      final secondary = resolve(
        variant: AppButtonVariant.secondary,
        states: {WidgetState.disabled},
      );
      expect(primary.background, secondary.background);
      expect(primary.foreground, secondary.foreground);
    });

    test('warning keeps its own yellow-tinted disabled surface', () {
      final warning = resolve(
        variant: AppButtonVariant.primary,
        intent: AppButtonIntent.warning,
        states: {WidgetState.disabled},
      );
      final standard = resolve(
        variant: AppButtonVariant.primary,
        states: {WidgetState.disabled},
      );
      expect(warning.background, colors.palettes.yellow.shade100);
      expect(warning.background, isNot(standard.background));
    });

    test('outline/transparent disabled keeps a neutral border', () {
      final surface = resolve(
        variant: AppButtonVariant.outline,
        states: {WidgetState.disabled},
      );
      expect(surface.background, Colors.transparent);
      expect(surface.hasBorder, isTrue);
    });
  });

  group('ButtonTokens.resolve — dark theme', () {
    const darkColors = DarkColors.colors;

    test("primary's default fill has no light/dark fork", () {
      final light = ButtonTokens.resolve(
        variant: AppButtonVariant.primary,
        colors: colors,
        brightness: Brightness.light,
        states: const {},
      );
      final dark = ButtonTokens.resolve(
        variant: AppButtonVariant.primary,
        colors: darkColors,
        brightness: Brightness.dark,
        states: const {},
      );
      expect(light.background, dark.background);
    });
  });

  group('ButtonTokens dimensions', () {
    testWidgets('block and large share the same height', (tester) async {
      await _initScreenUtil(tester);
      expect(
        ButtonTokens.minHeight(AppButtonSize.block),
        ButtonTokens.minHeight(AppButtonSize.large),
      );
    });

    testWidgets('small is shorter than block/large', (tester) async {
      await _initScreenUtil(tester);
      expect(
        ButtonTokens.minHeight(AppButtonSize.small),
        lessThan(ButtonTokens.minHeight(AppButtonSize.block)),
      );
    });

    testWidgets('padding is identical across all sizes', (tester) async {
      await _initScreenUtil(tester);
      final block = ButtonTokens.padding(AppButtonSize.block);
      final large = ButtonTokens.padding(AppButtonSize.large);
      final small = ButtonTokens.padding(AppButtonSize.small);
      expect(block, large);
      expect(block, small);
    });

    testWidgets('spinner size follows button size', (tester) async {
      await _initScreenUtil(tester);
      expect(
        ButtonTokens.spinnerSize(AppButtonSize.small),
        lessThan(ButtonTokens.spinnerSize(AppButtonSize.block)),
      );
    });
  });
}
