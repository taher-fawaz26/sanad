import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Figma `Controls / Text Fields` (`194:5445`) — bordered `AppSearchField`,
/// shared by the branch coverage-area map and the "add serving area" picker.
class PlaceSearchField extends StatelessWidget {
  const PlaceSearchField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    this.autofocus = false,
    this.isLoading = false,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final bool autofocus;
  final bool isLoading;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return AppSearchField(
      controller: controller,
      focusNode: focusNode,
      hint: hint,
      autofocus: autofocus,
      variant: AppSearchFieldVariant.bordered,
      showMicIcon: false,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    );
  }
}
