import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:maps/src/domain/entities/place_prediction.dart';
import 'package:maps/src/presentation/models/place_search_status.dart';
import 'package:maps/src/presentation/widgets/prediction_list.dart';

/// Localized strings for [PlaceSearchSheetBody]. Supplied by the caller so the
/// maps package stays locale-agnostic.
class PlaceSearchSheetLabels {
  const PlaceSearchSheetLabels({
    required this.hint,
    required this.emptyMessage,
    required this.errorMessage,
    required this.retryLabel,
  });

  final String hint;
  final String emptyMessage;
  final String errorMessage;
  final String retryLabel;
}

/// Bloc-agnostic body for the place-search modal sheet, mirroring the search
/// sheets in Branches/Workers: a bordered, autofocused search field over a
/// scrollable, state-driven results area (loading / results / empty / error).
///
/// It owns NO map or selection logic — it debounces query input via
/// [onQueryChanged] and reports the tapped result via [onPredictionTap]. The
/// host picker is responsible for animating the camera and updating selection.
class PlaceSearchSheetBody extends StatefulWidget {
  const PlaceSearchSheetBody({
    required this.labels,
    required this.predictions,
    required this.searchStatus,
    required this.searchQuery,
    required this.onQueryChanged,
    required this.onPredictionTap,
    this.errorMessage,
    super.key,
  });

  final PlaceSearchSheetLabels labels;
  final List<PlacePrediction> predictions;
  final PlaceSearchStatus searchStatus;
  final String searchQuery;

  /// Dynamic error text from the search backend; falls back to
  /// [PlaceSearchSheetLabels.errorMessage] when null.
  final String? errorMessage;

  final ValueChanged<String> onQueryChanged;
  final ValueChanged<PlacePrediction> onPredictionTap;

  @override
  State<PlaceSearchSheetBody> createState() => _PlaceSearchSheetBodyState();
}

class _PlaceSearchSheetBodyState extends State<PlaceSearchSheetBody> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _debouncer = Debouncer();

  @override
  void dispose() {
    _debouncer.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debouncer.run(() => widget.onQueryChanged(value));
  }

  void _retry() {
    _debouncer.cancel();
    widget.onQueryChanged(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: AppSearchField(
            controller: _controller,
            focusNode: _focusNode,
            variant: AppSearchFieldVariant.bordered,
            hint: widget.labels.hint,
            showMicIcon: false,
            autofocus: true,
            onChanged: _onChanged,
          ),
        ),
        Expanded(child: _buildResults(context)),
      ],
    );
  }

  Widget _buildResults(BuildContext context) {
    switch (widget.searchStatus) {
      case PlaceSearchStatus.searching:
        return const Center(child: AppLoadingIndicator());
      case PlaceSearchStatus.success:
        return PredictionList(
          predictions: widget.predictions,
          searchQuery: widget.searchQuery,
          onPredictionTap: widget.onPredictionTap,
        );
      case PlaceSearchStatus.empty:
        return _CenteredMessage(message: widget.labels.emptyMessage);
      case PlaceSearchStatus.failure:
        return _SearchError(
          message: widget.errorMessage ?? widget.labels.errorMessage,
          retryLabel: widget.labels.retryLabel,
          onRetry: _retry,
        );
      case PlaceSearchStatus.idle:
        return const SizedBox.shrink();
    }
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: context.appTypography.regularNormal.copyWith(
            color: context.appColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _SearchError extends StatelessWidget {
  const _SearchError({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: colors.error,
              size: responsiveDimension(32),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.appTypography.regularNormal.copyWith(
                color: colors.textSecondary,
              ),
            ),
            SizedBox(height: AppSpacing.md),
            AppButton(
              label: retryLabel,
              type: AppButtonType.secondary,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
