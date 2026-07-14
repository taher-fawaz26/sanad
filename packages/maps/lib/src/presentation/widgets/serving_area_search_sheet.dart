import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maps/src/domain/entities/serving_area.dart';
import 'package:maps/src/presentation/bloc/coverage_area/coverage_area_bloc.dart';
import 'package:maps/src/presentation/models/serving_area_search_labels.dart';
import 'package:maps/src/presentation/widgets/place_search_bar.dart';
import 'package:maps/src/presentation/widgets/serving_area_chips.dart';

class ServingAreaSearchSheet extends StatelessWidget {
  const ServingAreaSearchSheet({
    required this.labels,
    super.key,
  });

  final ServingAreaSearchLabels labels;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CoverageAreaBloc, CoverageAreaState>(
      buildWhen: (prev, curr) =>
          prev.servingAreas != curr.servingAreas ||
          prev.predictions != curr.predictions ||
          prev.searchStatus != curr.searchStatus ||
          prev.searchQuery != curr.searchQuery ||
          prev.searchError != curr.searchError,
      builder: (context, state) {
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: AppSpacing.md),
              Text(
                labels.title,
                style: context.appTypography.regularNormal
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: AppSpacing.sm),
              PlaceSearchBar(
                hint: labels.searchHint,
                predictions: state.predictions,
                searchStatus: state.searchStatus,
                searchQuery: state.searchQuery,
                emptyMessage: labels.noResultsMessage,
                errorMessage: state.searchError,
                onQueryChanged: (query) {
                  context.read<CoverageAreaBloc>().add(
                    CoverageAreaQueryChanged(query),
                  );
                },
                onSubmitted: (_) {},
                onPredictionSelected: (prediction) {
                  context.read<CoverageAreaBloc>().add(
                    CoverageAreaPredictionSelected(
                      prediction,
                    ),
                  );
                },
                onCleared: () {
                  context.read<CoverageAreaBloc>().add(
                    const CoverageAreaPredictionsCleared(),
                  );
                },
              ),
              SizedBox(height: AppSpacing.md),
              ServingAreaChips(
                areas: state.servingAreas,
                onRemoved: (area) {
                  context.read<CoverageAreaBloc>().add(
                    CoverageAreaServingAreaRemoved(
                      area.placeId,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<List<ServingArea>?> showServingAreaSearchSheet(
  BuildContext context, {
  required ServingAreaSearchLabels labels,
}) {
  return showAppBottomSheet<List<ServingArea>>(
    context: context,
    child: Builder(
      builder: (sheetContext) {
        return BlocProvider.value(
          value: context.read<CoverageAreaBloc>(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ServingAreaSearchSheet(labels: labels),
              Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: BlocBuilder<CoverageAreaBloc, CoverageAreaState>(
                  buildWhen: (prev, curr) =>
                      prev.servingAreas != curr.servingAreas,
                  builder: (context, state) {
                    return AppButton(
                      label: labels.confirm,
                      onPressed: () => Navigator.of(sheetContext)
                          .pop(state.servingAreas),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
