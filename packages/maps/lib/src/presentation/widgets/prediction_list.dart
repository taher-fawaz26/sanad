import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:maps/src/domain/entities/place_prediction.dart';
import 'package:maps/src/presentation/widgets/prediction_tile.dart';

class PredictionList extends StatelessWidget {
  const PredictionList({
    required this.predictions,
    required this.searchQuery,
    required this.onPredictionTap,
    super.key,
  });

  final List<PlacePrediction> predictions;
  final String searchQuery;
  final ValueChanged<PlacePrediction> onPredictionTap;

  @override
  Widget build(BuildContext context) {
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
        return PredictionTile(
          prediction: prediction,
          searchQuery: searchQuery,
          onTap: () => onPredictionTap(prediction),
        );
      },
    );
  }
}
