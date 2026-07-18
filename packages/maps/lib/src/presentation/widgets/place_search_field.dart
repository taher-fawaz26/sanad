import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class PlaceSearchField extends StatefulWidget {
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
  State<PlaceSearchField> createState() => _PlaceSearchFieldState();
}

class _PlaceSearchFieldState extends State<PlaceSearchField> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.isNotEmpty;
    widget.controller.addListener(_onTextChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChange);
    super.dispose();
  }

  void _onTextChange() {
    final hasText = widget.controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spec = context.appSearchBarTheme.spec;

    Widget trailing;
    if (widget.isLoading) {
      trailing = AppLoadingIndicator(
        size: spec.iconSize,
        strokeWidth: 2,
        color: spec.iconColor,
      );
    } else if (_hasText) {
      trailing = GestureDetector(
        onTap: widget.onClear,
        behavior: HitTestBehavior.opaque,
        child: Icon(
          Icons.close,
          size: spec.iconSize,
          color: spec.iconColor,
        ),
      );
    } else {
      trailing = const SizedBox.shrink();
    }

    return SizedBox(
      height: spec.height,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        height: spec.height,
        decoration: BoxDecoration(
          color: spec.backgroundColor,
          borderRadius: spec.borderRadius,
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            SizedBox(width: spec.iconPadding),
            Icon(
              Icons.search,
              size: spec.iconSize,
              color: spec.iconColor,
            ),
            SizedBox(width: spec.iconGap),
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                autofocus: widget.autofocus,
                style: spec.valueStyle,
                cursorColor: spec.cursorColor,
                textInputAction: TextInputAction.search,
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  isDense: true,
                  isCollapsed: true,
                  filled: false,
                  fillColor: Colors.transparent,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  constraints: const BoxConstraints(),
                  hintText: widget.hint,
                  hintStyle: spec.hintStyle,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
              ),
            ),
            SizedBox(width: spec.iconPadding),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: trailing,
            ),
            SizedBox(width: spec.iconPadding),
          ],
        ),
      ),
    );
  }
}
