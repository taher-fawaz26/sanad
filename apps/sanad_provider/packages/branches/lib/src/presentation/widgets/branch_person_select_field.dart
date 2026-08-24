import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Person picker preset — avatar prefix + [AppSelectField].
class BranchPersonSelectField extends StatelessWidget {
  const BranchPersonSelectField({
    required this.label,
    super.key,
    this.value,
    this.hint,
    this.avatar,
    this.onTap,
    this.enabled = true,
    this.isRequired = false,
    this.errorText,
  });

  final String label;
  final String? value;
  final String? hint;
  final Widget? avatar;
  final VoidCallback? onTap;
  final bool enabled;

  /// When `true`, appends a red `*` after the label.
  final bool isRequired;

  /// Inline error message shown below the field (injected string).
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return AppSelectField(
      label: label,
      value: value,
      hint: hint,
      prefix: avatar,
      onTap: onTap,
      enabled: enabled,
      isRequired: isRequired,
      errorText: errorText,
    );
  }
}
