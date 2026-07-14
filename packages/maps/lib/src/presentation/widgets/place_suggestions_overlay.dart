import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:maps/src/domain/entities/place_prediction.dart';
import 'package:maps/src/presentation/models/place_search_status.dart';
import 'package:maps/src/presentation/widgets/prediction_list.dart';

class PlaceSuggestionsOverlay extends StatelessWidget {
  const PlaceSuggestionsOverlay({
    required this.predictions,
    required this.searchStatus,
    required this.searchQuery,
    required this.onPredictionTap,
    this.emptyMessage,
    this.errorMessage,
    super.key,
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
      content = PredictionList(
        predictions: predictions,
        searchQuery: searchQuery,
        onPredictionTap: onPredictionTap,
      );
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
}
