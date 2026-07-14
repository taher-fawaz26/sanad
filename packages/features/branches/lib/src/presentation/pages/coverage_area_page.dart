import 'package:app_assets/app_assets.dart';
import 'package:branches/src/presentation/models/coverage_area_result.dart';
import 'package:branches/src/presentation/utils/branch_map_defaults.dart';
import 'package:branches/src/presentation/utils/serving_area_mapper.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:maps/maps.dart';

/// Figma Coverage area full screen (`194:5435`).
class CoverageAreaPage extends StatefulWidget {
  const CoverageAreaPage({super.key});

  @override
  State<CoverageAreaPage> createState() => _CoverageAreaPageState();
}

class _CoverageAreaPageState extends State<CoverageAreaPage> {
  static const _minRadiusKm = 1.0;
  static const _maxRadiusKm = 30.0;
  static const _mapOverlayAlpha = 0.45;
  static const _radiusSnapThresholdKm = 0.01;

  final _radiusDebouncer = Debouncer(delay: const Duration(milliseconds: 400));
  final _radiusController = MapRadiusController();
  final _cameraController = MapCameraController();
  double? _previewRadiusKm;
  bool _isDragging = false;

  @override
  void dispose() {
    _radiusDebouncer.dispose();
    _radiusController.dispose();
    _cameraController.dispose();
    super.dispose();
  }

  void _onCameraMove(CameraPosition position) {
    _cameraController.onCameraMove(position);
    if (!_isDragging) {
      setState(() => _isDragging = true);
    }
  }

  void _onCameraIdle() {
    if (!_isDragging) return;
    setState(() => _isDragging = false);
    final center = _cameraController.position.value;
    if (center == null) return;
    context.read<CoverageAreaBloc>().add(
      CoverageAreaMapMoved(center),
    );
  }

  void _onMapTap(LatLng latLng) {
    _cameraController.animateTo(
      latLng,
      zoom: BranchMapDefaults.coverageZoom,
    );
    context.read<CoverageAreaBloc>().add(
      CoverageAreaMapMoved(
        latLng,
        cameraSource: CoverageAreaCameraSource.programmatic,
      ),
    );
  }

  void _onSearchPredictionSelected(PlacePrediction prediction) {
    context.read<LocationPickerBloc>().add(
      LocationPickerPredictionSelected(prediction),
    );
  }

  Future<void> _openAddAreaPicker() async {
    final bloc = context.read<CoverageAreaBloc>();
    final state = bloc.state;
    final result = await showMapAreaPicker(
      context,
      initialPosition: state.center,
      initialAddress: state.address,
      localeIdentifier: context.locale.toString(),
      labels: MapAreaPickerLabels(
        title: 'branches.coverage_area.add_serving_area'.tr(),
        searchHint: 'branches.coverage_area.search_serving_area'.tr(),
        noResultsMessage: 'branches.coverage_area.no_areas_found'.tr(),
        searchError: 'branches.coverage_area.search_error'.tr(),
        specifiedLocation: 'branches.location_picker.specified_location'.tr(),
        addressHint: 'branches.location_picker.address_hint'.tr(),
        genericError: 'branches.location_picker.generic_error'.tr(),
        confirm: 'branches.coverage_area.done'.tr(),
      ),
    );
    if (!mounted || result == null) return;
    bloc.add(CoverageAreaExtraAreaSet(servingAreaFromPickerResult(result)));
  }

  void _confirm(CoverageAreaState state) {
    final center = state.center;
    final address = state.address;
    if (center == null || address == null) return;

    context.pop(
      CoverageAreaResult(
        position: center,
        address: address,
        radiusKm: state.radiusKm,
        autoAreaNames: state.autoAreas,
        extraAreas: state.extraAreas,
      ),
    );
  }

  void _syncRadiusController(CoverageAreaState state) {
    _radiusController.update(
      center: state.center,
      radiusKm: _previewRadiusKm ?? state.radiusKm,
    );
  }

  List<ServingArea> _autoAreasForDisplay(CoverageAreaState state) {
    final center = state.center ?? BranchMapDefaults.position;
    return state.autoAreas
        .map(
          (name) => ServingArea(
            placeId: name,
            name: name,
            address: '',
            latLng: center,
          ),
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<CoverageAreaBloc, CoverageAreaState>(
          listenWhen: (previous, current) =>
              previous.center != current.center ||
              previous.cameraSource != current.cameraSource ||
              previous.radiusKm != current.radiusKm,
          listener: (context, state) {
            if (state.cameraSource == CoverageAreaCameraSource.programmatic &&
                state.center != null) {
              _cameraController.animateTo(
                state.center!,
                zoom: BranchMapDefaults.coverageZoom,
              );
            }
            final preview = _previewRadiusKm;
            if (preview != null &&
                (preview - state.radiusKm).abs() < _radiusSnapThresholdKm) {
              setState(() => _previewRadiusKm = null);
            }
          },
        ),
        BlocListener<LocationPickerBloc, LocationPickerState>(
          listenWhen: (prev, curr) =>
              prev.position != curr.position && curr.position != null,
          listener: (context, lpState) {
            context.read<CoverageAreaBloc>().add(
              CoverageAreaMapMoved(
                lpState.position!,
                cameraSource: CoverageAreaCameraSource.programmatic,
              ),
            );
          },
        ),
      ],
      child: BlocBuilder<CoverageAreaBloc, CoverageAreaState>(
        builder: (context, state) {
          _syncRadiusController(state);
          final mapTarget = state.center ?? BranchMapDefaults.position;
          final displayRadiusKm = _previewRadiusKm ?? state.radiusKm;

          return Scaffold(
            backgroundColor: context.appColors.surface,
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppNavBar(
                    title: '',
                    showBackButton: true,
                    onLeadingTap: () => context.pop(),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(bottom: AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppSection(
                            title: 'branches.coverage_area.title'.tr(),
                            caption: 'branches.coverage_area.subtitle'.tr(),
                          ),
                          SizedBox(height: AppSpacing.md),
                          _buildSearchBar(context),
                          SizedBox(height: AppSpacing.md),
                          _buildMap(context, state, mapTarget),
                          SizedBox(height: AppSpacing.md),
                          _buildRadiusSection(
                            context,
                            state,
                            displayRadiusKm,
                          ),
                          SizedBox(height: AppSpacing.md),
                          _buildServingAreasSection(context, state),
                          if (state.failure != null) ...[
                            SizedBox(height: AppSpacing.sm),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.xl,
                              ),
                              child: Text(
                                state.failure!.message,
                                style: context.appTypography.smallNormal
                                    .copyWith(
                                      color: context.appColors.error,
                                    ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.sm,
                      AppSpacing.xl,
                      AppSpacing.sm,
                    ),
                    child: AppButton(
                      label: 'branches.coverage_area.confirm'.tr(),
                      onPressed: state.canConfirm
                          ? () => _confirm(state)
                          : null,
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

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: BlocBuilder<LocationPickerBloc, LocationPickerState>(
        buildWhen: (prev, curr) =>
            prev.predictions != curr.predictions ||
            prev.searchStatus != curr.searchStatus ||
            prev.searchQuery != curr.searchQuery ||
            prev.searchError != curr.searchError,
        builder: (context, lpState) {
          return PlaceSearchBar(
            hint: 'branches.coverage_area.search_hint'.tr(),
            predictions: lpState.predictions,
            searchStatus: lpState.searchStatus,
            searchQuery: lpState.searchQuery,
            errorMessage: lpState.searchError,
            onQueryChanged: (query) {
              context.read<LocationPickerBloc>().add(
                LocationPickerQueryChanged(query),
              );
            },
            onSubmitted: (_) {},
            onPredictionSelected: _onSearchPredictionSelected,
            onCleared: () {
              context.read<LocationPickerBloc>().add(
                const LocationPickerPredictionsCleared(),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMap(
    BuildContext context,
    CoverageAreaState state,
    LatLng mapTarget,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: SizedBox(
        height: responsiveDimension(320),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            responsiveDimension(20),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AppGoogleMap(
                initialCameraPosition: CameraPosition(
                  target: mapTarget,
                  zoom: BranchMapDefaults.coverageZoom,
                ),
                circles: _radiusController.buildCircles(
                  strokeColor: context.appColors.primary,
                  style: const RadiusOverlayStyle(
                    circleId: 'coverage_radius',
                  ),
                ),
                onMapCreated: (controller) {
                  _cameraController.onMapCreated(controller);
                  if (state.center != null) {
                    _cameraController.animateTo(
                      state.center!,
                      zoom: BranchMapDefaults.coverageZoom,
                    );
                  }
                },
                onCameraMove: _onCameraMove,
                onCameraIdle: _onCameraIdle,
                onTap: _onMapTap,
                tiltGesturesEnabled: false,
                rotateGesturesEnabled: false,
              ),
              IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _isDragging ? 0.5 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: AppSvgPicture.asset(
                    AppSvgs.mapPinMarker,
                    width: responsiveDimension(24),
                    height: responsiveDimension(32),
                  ),
                ),
              ),
              if (state.isLoading)
                ColoredBox(
                  color: context.appColors.surface.withValues(
                    alpha: _mapOverlayAlpha,
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadiusSection(
    BuildContext context,
    CoverageAreaState state,
    double displayRadiusKm,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSection(
            title: 'branches.coverage_area.radius'.tr(),
            size: AppSectionSize.compact,
            trailing: AppSectionTrailing.custom,
            trailingWidget: Text(
              'branches.coverage_area.radius_value'.tr(
                namedArgs: {
                  'value': formatRadiusKm(displayRadiusKm),
                },
              ),
              style: context.appTypography.regularNormal.copyWith(
                fontWeight: FontWeight.w500,
                color: context.appColors.textPrimary,
              ),
            ),
            padding: EdgeInsets.zero,
          ),
          AppSlider(
            value: displayRadiusKm.clamp(
              _minRadiusKm,
              _maxRadiusKm,
            ),
            min: _minRadiusKm,
            max: _maxRadiusKm,
            onChanged: (value) {
              setState(() => _previewRadiusKm = value);
              _radiusDebouncer.run(() {
                if (!mounted) return;
                context.read<CoverageAreaBloc>().add(
                  CoverageAreaRadiusChanged(value),
                );
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServingAreasSection(
    BuildContext context,
    CoverageAreaState state,
  ) {
    final autoAreas = _autoAreasForDisplay(state);
    final extraAreas = state.extraAreas;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSection(
            title: 'branches.coverage_area.covered_areas'.tr(),
            size: AppSectionSize.compact,
            trailing: AppSectionTrailing.custom,
            trailingWidget: Text(
              'branches.coverage_area.areas_count'.tr(
                namedArgs: {
                  'count': '${state.totalAreaCount}',
                },
              ),
              style: context.appTypography.regularNormal.copyWith(
                fontWeight: FontWeight.w500,
                color: context.appColors.textPrimary,
              ),
            ),
            padding: EdgeInsets.zero,
          ),
          SizedBox(height: AppSpacing.sm),
          ServingAreaChips(
            areas: autoAreas,
            emptyMessage: 'branches.coverage_area.no_areas_message'.tr(),
            onRemoved: (area) {
              context.read<CoverageAreaBloc>().add(
                CoverageAreaAutoAreaRemoved(area.name),
              );
            },
          ),
          if (extraAreas.isNotEmpty) ...[
            SizedBox(height: AppSpacing.sm),
            ServingAreaChips(
              areas: extraAreas,
              onRemoved: (area) {
                context.read<CoverageAreaBloc>().add(
                  CoverageAreaExtraAreaRemoved(area),
                );
              },
            ),
          ],
          SizedBox(height: AppSpacing.sm),
          AppChip(
            label: 'branches.coverage_area.add_area'.tr(),
            selected: true,
            iconPosition: AppChipIconPosition.left,
            icon: Icon(
              Icons.add,
              size: AppDimension.iconCompact,
              color: context.appColors.onPrimary,
            ),
            onTap: _openAddAreaPicker,
          ),
        ],
      ),
    );
  }
}
