import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:maps/src/domain/entities/place_prediction.dart';

class PlaceSearchBar extends StatefulWidget {
  const PlaceSearchBar({
    required this.hint,
    required this.predictions,
    required this.onQueryChanged,
    required this.onSubmitted,
    required this.onPredictionSelected,
    this.onCleared,
    this.isLoading = false,
    this.controller,
    super.key,
  });

  final String hint;
  final List<PlacePrediction> predictions;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<PlacePrediction> onPredictionSelected;
  final VoidCallback? onCleared;
  final bool isLoading;
  final TextEditingController? controller;

  @override
  State<PlaceSearchBar> createState() => _PlaceSearchBarState();
}

class _PlaceSearchBarState extends State<PlaceSearchBar> {
  late final TextEditingController _controller;
  final _debouncer = Debouncer();

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    _debouncer.run(() {
      if (!mounted) return;
      widget.onQueryChanged(query);
    });
  }

  void _onSubmitted(String query) {
    _debouncer.cancel();
    widget.onCleared?.call();
    widget.onSubmitted(query);
  }

  void _onPredictionTap(PlacePrediction prediction) {
    _controller.clear();
    widget.onPredictionSelected(prediction);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSearchField(
          controller: _controller,
          hint: widget.hint,
          showMicIcon: false,
          onChanged: _onChanged,
          onSubmitted: _onSubmitted,
        ),
        if (widget.predictions.isNotEmpty)
          _PredictionsList(
            predictions: widget.predictions,
            onTap: _onPredictionTap,
          ),
      ],
    );
  }
}

class _PredictionsList extends StatelessWidget {
  const _PredictionsList({
    required this.predictions,
    required this.onTap,
  });

  final List<PlacePrediction> predictions;
  final ValueChanged<PlacePrediction> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Container(
      margin: EdgeInsets.only(top: AppSpacing.xs),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(responsiveDimension(12)),
        boxShadow: AppShadows.small,
      ),
      constraints: BoxConstraints(
        maxHeight: responsiveDimension(200),
      ),
      child: ListView.separated(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
        shrinkWrap: true,
        itemCount: predictions.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final prediction = predictions[index];
          return InkWell(
            onTap: () => onTap(prediction),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: responsiveDimension(20),
                    color: colors.onSurfaceVariant,
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          prediction.mainText,
                          style: typography.regularNormal.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (prediction.secondaryText.isNotEmpty)
                          Text(
                            prediction.secondaryText,
                            style: typography.smallNormal.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
