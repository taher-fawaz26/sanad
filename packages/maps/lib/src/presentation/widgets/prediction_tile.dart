import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:maps/src/domain/entities/place_prediction.dart';

class PredictionTile extends StatelessWidget {
  const PredictionTile({
    required this.prediction,
    required this.searchQuery,
    required this.onTap,
    super.key,
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
