import 'package:app_assets/app_assets.dart';
import 'package:design_system/src/theme/tokens/search_bar_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Figma `Bars / Search Bars` — Branches instance (`73:2915` / Default `40:7016`).
///
/// Flat Sky/Lighter bar, 36×8 radius, search icon at start. Optional mic at end.
/// Cancel is opt-in via [showCancelOnFocus] (Focused/Filled component states).
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    this.controller,
    this.focusNode,
    this.hint = 'Search',
    this.cancelLabel = 'Cancel',
    this.onCancel,
    this.onChanged,
    this.onSubmitted,
    this.onMicTap,
    this.showMicIcon = true,
    this.showCancelOnFocus = false,
    this.showClearWhenFilled = false,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hint;
  final String cancelLabel;
  final VoidCallback? onCancel;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onMicTap;
  final bool showMicIcon;
  final bool showCancelOnFocus;
  final bool showClearWhenFilled;
  final bool autofocus;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late final TextEditingController _controller;
  late final bool _ownsController;
  late final FocusNode _focusNode;
  late final bool _ownsFocusNode;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TextEditingController();
    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
    _focused = widget.autofocus;
    _focusNode.addListener(_handleFocusChange);
    _controller.addListener(_handleTextChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _controller.removeListener(_handleTextChange);
    if (_ownsFocusNode) _focusNode.dispose();
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

  bool get _showCancel => widget.showCancelOnFocus && _focused;
  bool get _hasText => _controller.text.isNotEmpty;
  bool get _showClear =>
      _hasText && (widget.showClearWhenFilled || (_focused && _hasText));
  bool get _showMic => widget.showMicIcon && !_focused && !_showClear;

  void _handleCancel() {
    _focusNode.unfocus();
    widget.onCancel?.call();
  }

  void _handleClear() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  Widget _svgIcon(String asset, SearchBarStyleSpec spec) {
    return SvgPicture.asset(
      asset,
      package: AppAssets.package,
      width: spec.iconSize,
      height: spec.iconSize,
      colorFilter: ColorFilter.mode(spec.iconColor, BlendMode.srcIn),
      fit: BoxFit.contain,
    );
  }

  @override
  Widget build(BuildContext context) {
    final spec = context.appSearchBarTheme.spec;

    Widget? trailing;
    if (_showClear) {
      trailing = GestureDetector(
        onTap: _handleClear,
        behavior: HitTestBehavior.opaque,
        child: widget.showClearWhenFilled
            ? _svgIcon(AppSvgs.xCircle, spec)
            : Icon(
                Icons.close,
                size: spec.iconSize,
                color: spec.iconColor,
              ),
      );
    } else if (_showMic) {
      trailing = GestureDetector(
        onTap: widget.onMicTap,
        behavior: HitTestBehavior.opaque,
        child: _svgIcon(AppSvgs.mic, spec),
      );
    }

    return SizedBox(
      height: spec.height,
      child: Row(
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              height: spec.height,
              margin: EdgeInsetsDirectional.only(
                end: _showCancel ? spec.cancelGap : 0,
              ),
              decoration: BoxDecoration(
                color: spec.backgroundColor,
                borderRadius: spec.borderRadius,
              ),
              clipBehavior: Clip.antiAlias,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(width: spec.iconPadding),
                  _svgIcon(AppSvgs.search, spec),
                  SizedBox(width: spec.iconGap),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      autofocus: widget.autofocus,
                      style: spec.valueStyle,
                      cursorColor: spec.cursorColor,
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
                        // Override theme's 48px field constraints.
                        constraints: const BoxConstraints(),
                        hintText: widget.hint,
                        hintStyle: spec.hintStyle,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: widget.onChanged,
                      onSubmitted: widget.onSubmitted,
                    ),
                  ),
                  if (trailing != null) ...[
                    SizedBox(width: spec.iconPadding),
                    trailing,
                  ],
                  SizedBox(width: spec.iconPadding),
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
