import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:maps/src/domain/entities/place_prediction.dart';
import 'package:maps/src/presentation/models/place_search_status.dart';
import 'package:maps/src/presentation/widgets/place_search_field.dart';
import 'package:maps/src/presentation/widgets/place_suggestions_overlay.dart';

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
            child: PlaceSuggestionsOverlay(
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
    return TapRegion(
      groupId: _layerLink,
      child: CompositedTransformTarget(
        link: _layerLink,
        child: PlaceSearchField(
          controller: _controller,
          focusNode: _focusNode,
          hint: widget.hint,
          autofocus: widget.autofocus,
          isLoading: widget.searchStatus == PlaceSearchStatus.searching,
          onChanged: _onChanged,
          onSubmitted: _onSubmitted,
          onClear: _onClearTap,
        ),
      ),
    );
  }
}
