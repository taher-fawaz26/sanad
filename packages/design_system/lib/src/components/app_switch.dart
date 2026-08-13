import 'package:design_system/src/theme/tokens/switch_tokens.dart';
import 'package:flutter/material.dart';

/// Figma `Controls / Switches` (`40:7496`).
///
/// [loading] renders a spinner inside the knob instead of moving it — the
/// track keeps whatever [value] the caller passes (usually the previous,
/// pre-toggle value, since it's still awaiting a server response) and
/// ignores taps until the caller clears [loading]. Mirrors the iOS
/// Bluetooth-switch pattern: the switch stays put and busy while a request
/// is in flight, then the caller flips [value] on success or leaves it as
/// is on failure.
class AppSwitch extends StatelessWidget {
  const AppSwitch({
    required this.value,
    required this.onChanged,
    this.loading = false,
    super.key,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  /// Shows a spinner in the knob and blocks taps while `true`.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final spec = Theme.of(context).extension<AppSwitchTheme>()!.spec;
    final enabled = onChanged != null && !loading;
    // Loading keeps the "on" styling (not the greyed-out disabled styling)
    // so the switch still reads as interactive, just busy.
    final styledAsEnabled = onChanged != null;

    return Semantics(
      toggled: value,
      enabled: enabled,
      child: GestureDetector(
        onTap: enabled ? () => onChanged!(!value) : null,
        child: AnimatedContainer(
          duration: spec.animationDuration,
          width: spec.trackWidth,
          height: spec.trackHeight,
          decoration: BoxDecoration(
            color: spec.trackColor(value: value, enabled: styledAsEnabled),
            borderRadius: spec.trackRadius,
            border: spec.trackBorder(value: value, enabled: styledAsEnabled),
          ),
          child: AnimatedAlign(
            duration: spec.animationDuration,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: spec.knobSize,
              height: spec.knobSize,
              margin: EdgeInsets.all(spec.knobInset),
              decoration: BoxDecoration(
                color: spec.knobColor(value: value, enabled: styledAsEnabled),
                shape: BoxShape.circle,
              ),
              child: loading
                  ? Padding(
                      padding: EdgeInsets.all(spec.knobInset * 3),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                          spec.trackColor(value: value, enabled: true),
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
