import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import 'package:shared_widgets/src/components/app_svg_picture.dart';

/// Location field preset — map icon + inline set action.
class AppLocationField extends StatelessWidget {
  const AppLocationField({
    required this.label,
    required this.actionLabel,
    super.key,
    this.value,
    this.hint,
    this.onActionTap,
    this.onTap,
    this.enabled = true,
  });

  final String label;
  final String? value;
  final String? hint;
  final String actionLabel;
  final VoidCallback? onActionTap;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final iconSize = AppDimension.iconLg;

    return AppFieldAction(
      label: label,
      value: value,
      hint: hint,
      actionLabel: actionLabel,
      onActionTap: onActionTap,
      onTap: onTap,
      enabled: enabled,
      leading: AppSvgPicture.asset(
        AppSvgs.map,
        width: iconSize,
        height: iconSize,
      ),
    );
  }
}
