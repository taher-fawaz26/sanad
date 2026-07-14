import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:maps/src/domain/entities/place_prediction.dart';
import 'package:maps/src/presentation/models/place_search_status.dart';

class PlaceSearchBar extends StatefulWidget {
  const PlaceSearchBar({
    required this.hint,
    required this.predictions,
    required this.searchStatus,
    required this.onQueryChanged,
    required this.onSubmitted,
    required this.onPredictionSelected,
    this.onCleared,
    this.onFocusChanged,
    this.controller,
    this.focusNode,
    this.emptyMessage,
    this.errorMessage,
    this.searchQuery = '',
    this.autofocus = false,
    super.key,
  });

  final String hint;
  final List<PlacePrediction> predictions;
  final PlaceSearchStatus searchStatus;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<PlacePrediction> onPredictionSelected;
  final VoidCallback? onCleared;
  final ValueChanged<bool>? onFocusChanged;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? emptyMessage;
  final String? errorMessage;
  final String searchQuery;
  final bool autofocus;

  @override
  State<PlaceSearchBar> createState() => _PlaceSearchBarState();
}

class _PlaceSearchBarState extends State<PlaceSearchBar>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  final _debouncer = Debouncer();
  final _layerLink = LayerLink();

  OverlayEntry? _overlayEntry;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  bool _hasFocus = false;
  bool _hasQuery = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
    _hasQuery = _controller.text.trim().length >= 2;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.08),
      end: Offset.zero,
    ).animate(_fadeAnimation);
  }

  @override
  void didUpdateWidget(covariant PlaceSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.predictions != widget.predictions ||
        oldWidget.searchStatus != widget.searchStatus ||
        oldWidget.errorMessage != widget.errorMessage) {
      _updateOverlay();
    }
  }

  @override
  void dispose() {
    _hideOverlay();
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) _focusNode.dispose();
    if (widget.controller == null) _controller.dispose();
    _debouncer.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    final hadFocus = _hasFocus;
    _hasFocus = _focusNode.hasFocus;
    widget.onFocusChanged?.call(_hasFocus);
    if (hadFocus != _hasFocus) {
      _updateOverlay();
    }
  }

  bool get _shouldShowOverlay {
    if (!_hasFocus) return false;
    if (widget.predictions.isNotEmpty) return true;
    if (widget.searchStatus == PlaceSearchStatus.searching && _hasQuery) {
      return true;
    }
    if (widget.errorMessage != null && _hasQuery) return true;
    return false;
  }

  void _updateOverlay() {
    final should = _shouldShowOverlay;
    if (should) {
      if (_overlayEntry == null) {
        _showOverlay();
      } else {
        _overlayEntry!.markNeedsBuild();
        if (!_animationController.isCompleted) {
          _animationController.forward();
        }
      }
    } else {
      _hideOverlay();
    }
  }

  void _showOverlay() {
    _hideOverlay();
    _overlayEntry = OverlayEntry(builder: (_) => _buildOverlay());
    Overlay.of(context).insert(_overlayEntry!);
    _animationController.forward(from: 0);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry?.dispose();
    _overlayEntry = null;
    if (_animationController.isAnimating) {
      _animationController.reset();
    }
  }

  void _onChanged(String query) {
    _hasQuery = query.trim().length >= 2;
    _debouncer.run(() {
      if (!mounted) return;
      widget.onQueryChanged(query);
    });
    if (!_hasQuery) {
      _updateOverlay();
    }
  }

  void _onSubmitted(String query) {
    _debouncer.cancel();
    // Keep predictions visible — user must explicitly tap one.
    // Only fall through to ForwardGeocode when no predictions exist.
    if (widget.predictions.isNotEmpty) {
      _focusNode.requestFocus();
      return;
    }
    widget.onCleared?.call();
    _focusNode.unfocus();
    widget.onSubmitted(query);
  }

  void _onPredictionTap(PlacePrediction prediction) {
    _controller.clear();
    _hasQuery = false;
    _focusNode.unfocus();
    widget.onPredictionSelected(prediction);
  }

  void _onDismiss() {
    _focusNode.unfocus();
    _hideOverlay();
  }

  void _onClearTap() {
    _controller.clear();
    _hasQuery = false;
    widget.onCleared?.call();
    _focusNode.requestFocus();
  }

  Widget _buildOverlay() {
    return TapRegion(
      groupId: _layerLink,
      onTapOutside: (_) => _onDismiss(),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CompositedTransformFollower(
            link: _layerLink,
            targetAnchor: Alignment.bottomLeft,
            child: _OverlayContent(
              predictions: widget.predictions,
              searchStatus: widget.searchStatus,
              searchQuery: widget.searchQuery,
              emptyMessage: widget.emptyMessage,
              errorMessage: widget.errorMessage,
              onPredictionTap: _onPredictionTap,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spec = context.appSearchBarTheme.spec;

    return TapRegion(
      groupId: _layerLink,
      child: CompositedTransformTarget(
        link: _layerLink,
        child: _SearchField(
          controller: _controller,
          focusNode: _focusNode,
          hint: widget.hint,
          autofocus: widget.autofocus,
          isLoading: widget.searchStatus == PlaceSearchStatus.searching,
          onChanged: _onChanged,
          onSubmitted: _onSubmitted,
          onClear: _onClearTap,
          spec: spec,
        ),
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.autofocus,
    required this.isLoading,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.spec,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final bool autofocus;
  final bool isLoading;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final SearchBarStyleSpec spec;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
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
    final spec = widget.spec;

    Widget trailing;
    if (widget.isLoading) {
      trailing = SizedBox(
        width: spec.iconSize,
        height: spec.iconSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: spec.iconColor,
        ),
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

class _OverlayContent extends StatelessWidget {
  const _OverlayContent({
    required this.predictions,
    required this.searchStatus,
    required this.searchQuery,
    required this.onPredictionTap,
    this.emptyMessage,
    this.errorMessage,
  });

  final List<PlacePrediction> predictions;
  final PlaceSearchStatus searchStatus;
  final String searchQuery;
  final String? emptyMessage;
  final String? errorMessage;
  final ValueChanged<PlacePrediction> onPredictionTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    Widget content;
    if (searchStatus == PlaceSearchStatus.searching && predictions.isEmpty) {
      content = _buildLoading(colors);
    } else if (errorMessage != null && predictions.isEmpty) {
      content = _buildError(colors, typography);
    } else if (predictions.isEmpty) {
      if (emptyMessage == null) return const SizedBox.shrink();
      content = _buildEmpty(colors, typography);
    } else {
      content = _buildPredictions(colors, typography);
    }

    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.xs),
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(responsiveDimension(12)),
        clipBehavior: Clip.antiAlias,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(responsiveDimension(12)),
            boxShadow: AppShadows.medium,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: responsiveDimension(280),
            ),
            child: content,
          ),
        ),
      ),
    );
  }

  Widget _buildLoading(AppColors colors) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Center(
        child: SizedBox(
          width: responsiveDimension(24),
          height: responsiveDimension(24),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildError(AppColors colors, AppTypography typography) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: responsiveDimension(20),
            color: colors.error,
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              errorMessage!,
              style: typography.smallNormal.copyWith(color: colors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(AppColors colors, AppTypography typography) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Text(
        emptyMessage!,
        style: typography.smallNormal.copyWith(
          color: colors.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildPredictions(AppColors colors, AppTypography typography) {
    return ListView.separated(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
      shrinkWrap: true,
      itemCount: predictions.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        indent: AppSpacing.md + responsiveDimension(20) + AppSpacing.sm,
      ),
      itemBuilder: (context, index) {
        final prediction = predictions[index];
        return _PredictionTile(
          prediction: prediction,
          searchQuery: searchQuery,
          onTap: () => onPredictionTap(prediction),
        );
      },
    );
  }
}

class _PredictionTile extends StatelessWidget {
  const _PredictionTile({
    required this.prediction,
    required this.searchQuery,
    required this.onTap,
  });

  final PlacePrediction prediction;
  final String searchQuery;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + AppSpacing.xs,
        ),
        child: Row(
          children: [
            Container(
              width: responsiveDimension(36),
              height: responsiveDimension(36),
              decoration: BoxDecoration(
                color: colors.controlFill,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.location_on_outlined,
                size: responsiveDimension(18),
                color: colors.onSurfaceVariant,
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _HighlightedText(
                    text: prediction.mainText,
                    query: searchQuery,
                    baseStyle: typography.regularNormal.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    highlightStyle: typography.regularNormal.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                  if (prediction.secondaryText.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: AppSpacing.xs / 2),
                      child: Text(
                        prediction.secondaryText,
                        style: typography.smallNormal.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightedText extends StatelessWidget {
  const _HighlightedText({
    required this.text,
    required this.query,
    required this.baseStyle,
    required this.highlightStyle,
  });

  final String text;
  final String query;
  final TextStyle baseStyle;
  final TextStyle highlightStyle;

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(
        text,
        style: baseStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final index = lowerText.indexOf(lowerQuery);

    if (index < 0) {
      return Text(
        text,
        style: baseStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Text.rich(
      TextSpan(
        children: [
          if (index > 0)
            TextSpan(text: text.substring(0, index), style: baseStyle),
          TextSpan(
            text: text.substring(index, index + query.length),
            style: highlightStyle,
          ),
          if (index + query.length < text.length)
            TextSpan(
              text: text.substring(index + query.length),
              style: baseStyle,
            ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
