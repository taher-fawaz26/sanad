import 'package:design_system/src/theme/tokens/search_bar_tokens.dart';
import 'package:flutter/material.dart';

/// Figma `Bars / Search Bars` (`40:6999`).
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    this.controller,
    this.hint = 'Search',
    this.cancelLabel = 'Cancel',
    this.onCancel,
    this.onChanged,
    this.onSubmitted,
    this.showMicIcon = true,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final String hint;
  final String cancelLabel;
  final VoidCallback? onCancel;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool showMicIcon;
  final bool autofocus;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late final TextEditingController _controller;
  late final bool _ownsController;
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TextEditingController();
    _focused = widget.autofocus;
    _focusNode.addListener(_handleFocusChange);
    _controller.addListener(_handleTextChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _controller.removeListener(_handleTextChange);
    _focusNode.dispose();
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() => _focused = _focusNode.hasFocus);
  }

  void _handleTextChange() {
    setState(() {});
  }

  bool get _showCancel => _focused;
  bool get _hasText => _controller.text.isNotEmpty;

  void _handleCancel() {
    _focusNode.unfocus();
    widget.onCancel?.call();
  }

  void _handleClear() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final spec = context.appSearchBarTheme.spec;

    return SizedBox(
      height: spec.height,
      child: Row(
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              margin: EdgeInsets.only(
                right: _showCancel ? spec.cancelGap : 0,
              ),
              decoration: BoxDecoration(
                color: spec.backgroundColor,
                borderRadius: spec.borderRadius,
              ),
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
                      controller: _controller,
                      focusNode: _focusNode,
                      autofocus: widget.autofocus,
                      style: spec.valueStyle,
                      cursorColor: spec.cursorColor,
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: widget.hint,
                        hintStyle: spec.hintStyle,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: widget.onChanged,
                      onSubmitted: widget.onSubmitted,
                    ),
                  ),
                  if (_hasText && _focused) ...[
                    GestureDetector(
                      onTap: _handleClear,
                      child: Icon(
                        Icons.close,
                        size: spec.iconSize,
                        color: spec.iconColor,
                      ),
                    ),
                    SizedBox(width: spec.iconPadding),
                  ] else if (widget.showMicIcon && !_focused) ...[
                    Icon(
                      Icons.mic_none,
                      size: spec.iconSize,
                      color: spec.iconColor,
                    ),
                    SizedBox(width: spec.iconPadding),
                  ],
                ],
              ),
            ),
          ),
          if (_showCancel)
            SizedBox(
              width: spec.cancelAreaWidth,
              child: GestureDetector(
                onTap: _handleCancel,
                child: Text(
                  widget.cancelLabel,
                  style: spec.cancelStyle,
                  textAlign: TextAlign.end,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
