import 'package:design_system/design_system.dart' show AppButtonGroup;
import 'package:design_system/src/components/app_button_group.dart'
    show AppButtonGroup;
import 'package:design_system/src/components/components.dart'
    show AppButtonGroup;
import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:flutter/material.dart';

/// Resolved styling for [AppButtonGroup].
@immutable
class ButtonGroupStyleSpec {
  const ButtonGroupStyleSpec({
    required this.gap,
    required this.buttonFlex,
  });

  final double gap;
  final int buttonFlex;
}

/// Figma `Controls / Button Groups` (`251:6533`) token resolver.
abstract final class ButtonGroupTokens {
  ButtonGroupTokens._();

  static const double gap = 16;
  static const int buttonFlex = 1;

  static ButtonGroupStyleSpec resolve() {
    return ButtonGroupStyleSpec(
      gap: responsiveDimension(gap),
      buttonFlex: buttonFlex,
    );
  }
}
