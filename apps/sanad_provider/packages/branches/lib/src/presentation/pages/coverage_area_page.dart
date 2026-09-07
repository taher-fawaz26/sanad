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
import 'package:sheet_navigation/sheet_navigation.dart';

/// Figma Coverage area full screen (`194:5435`).
class CoverageAreaPage extends StatefulWidget {
  const CoverageAreaPage({super.key});

  @override
  State<CoverageAreaPage> createState() => _CoverageAreaPageState();
}

class _CoverageAreaPageState extends State<CoverageAreaPage> {
  static const _mapOverlayAlpha = 0.45;
  static const _radiusSnapThresholdKm = 0.01;

  // Radius bounds come from MapsConfig (product/config limits, not hardcoded
  // here): min matches the backend's `radiusKm >= 1`; max is the product
  // ceiling on how large a single grid-tessellated discovery may be.
  double get _minRadiusKm => 1;
  double get _maxRadiusKm => sl<MapsConfig>().servingAreaDiscovery.maxRadiusKm;

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
    // A programmatic animation (initial center, prediction jump, map tap,
    // radius sync) also produces a move→idle sequence. Those paths dispatch
    // their own CoverageAreaMapMoved(programmatic); treating this idle as a
    // user pan would fire a second, spurious resolve that overwrites the
    // seeded/loaded serving areas. Only real user pans reach the bloc here.
    if (_cameraController.isAnimating.value) return;
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

  Future<void> _openSearchSheet(BuildContext context) async {
    final bloc = context.read<LocationPickerBloc>();
    final selected = await SheetNavigator.push<PlacePrediction>(
      context,
      BlocProvider.value(
        value: bloc,
        child: BlocBuilder<LocationPickerBloc, LocationPickerState>(
          builder: (context, state) => PlaceSearchSheetBody(
            labels: PlaceSearchSheetLabels(
              hint: 'branches.coverage_area.search_hint'.tr(),
              emptyMessage: 'branches.coverage_area.no_areas_found'.tr(),
              errorMessage: 'branches.coverage_area.search_error'.tr(),
              retryLabel: 'common.retry'.tr(),
            ),
            predictions: state.predictions,
            searchStatus: state.searchStatus,
            searchQuery: state.searchQuery,
            errorMessage: state.searchError,
            onQueryChanged: (q) => context.read<LocationPickerBloc>().add(
              LocationPickerQueryChanged(q),
            ),
            onPredictionTap: (p) => Navigator.of(context).pop(p),
          ),
        ),
      ),
      settings: const SheetRouteSettings(sheetSize: SheetSize.expanded),
    );
    bloc.add(const LocationPickerPredictionsCleared());
    if (selected != null) {
      bloc.add(LocationPickerPredictionSelected(selected));
    }
  }

  Future<void> _openAddAreaPicker() async {
    final bloc = context.read<CoverageAreaBloc>();
    final state = bloc.state;
    final result = await showMapAreaPicker(
      context,
      // Start the area picker near the coverage center the caller already has.
      initialLocation: state.center,
      initialAddress: state.address,
      localeIdentifier: context.locale.toString(),
      requirePlaceId: true,
      labels: MapAreaPickerLabels(
        title: 'branches.coverage_area.add_serving_area'.tr(),
        searchHint: 'branches.coverage_area.search_serving_area'.tr(),
        noResultsMessage: 'branches.coverage_area.no_areas_found'.tr(),
        searchError: 'branches.coverage_area.search_error'.tr(),
        specifiedLocation: 'branches.location_picker.specified_location'.tr(),
        addressHint: 'branches.location_picker.address_hint'.tr(),
        genericError: 'branches.location_picker.generic_error'.tr(),
        confirm: 'branches.coverage_area.done'.tr(),
        searchRetry: 'common.retry'.tr(),
        placeIdRequiredHint: 'branches.coverage_area.select_from_search_hint'
            .tr(),
      ),
    );
    if (!mounted || result == null) return;
    final area = servingAreaFromPickerResult(result);
    if (area == null) return;
    bloc.add(CoverageAreaExtraAreaSet(area));
  }

  void _confirm(CoverageAreaState state) {
    final center = state.center;
    final address = state.address;
    if (center == null || address == null) return;

    final placeId = context.read<LocationPickerBloc>().state.selectedPlaceId;
    context.pop(
      CoverageAreaResult(
        position: center,
        address: address,
        radiusKm: state.radiusKm,
        placeId: placeId,
        autoAreas: state.autoAreas,
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

  List<ServingArea> _autoAreasForDisplay(CoverageAreaState state) =>
      state.autoAreas;

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
            // Sync the radius overlay whenever center or radius changes.
            _syncRadiusController(state);

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
                                _localizedFailure(state.failure!),
                                style: context.appTypography.smallNormal
                                    .copyWith(
                                      color: context.appColors.error,
                                    ),
                              ),
                            ),
                          ] else if (state.discoveryStatus ==
                              CoverageAreaDiscoveryStatus.partialFailure) ...[
                            // Discovery is bounded, grid-tessellated reverse
                            // geocoding — never claim exhaustive coverage.
                            SizedBox(height: AppSpacing.sm),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.xl,
                              ),
                              child: Text(
                                'branches.coverage_area.partial_discovery_notice'
                                    .tr(),
                                style: context.appTypography.smallNormal
                                    .copyWith(
                                      color: context.appColors.textSecondary,
                                    ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                      AppSpacing.xl,
                      AppSpacing.sm,
                      AppSpacing.xl,
                      AppSpacing.sm,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (state.isOutsideCountry) ...[
                          Text(
                            'branches.coverage_area.outside_uae'.tr(),
                            textAlign: TextAlign.center,
                            style: context.appTypography.smallNormal.copyWith(
                              color: context.appColors.error,
                            ),
                          ),
                          SizedBox(height: AppSpacing.sm),
                        ],
                        AppButton(
                          label: 'branches.coverage_area.confirm'.tr(),
                          onPressed: state.canConfirm
                              ? () => _confirm(state)
                              : null,
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

  Widget _buildSearchBar(BuildContext context) {
    // Tap-to-open trigger — the live search lives in the modal sheet.
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: AppSearchField(
        variant: AppSearchFieldVariant.bordered,
        hint: 'branches.coverage_area.search_hint'.tr(),
        showMicIcon: false,
        readOnly: true,
        onTap: () => _openSearchSheet(context),
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
                cameraTargetBounds: CameraTargetBounds(
                  DefaultMapViewport.uaeBounds,
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
                    child: AppLoadingIndicator(),
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
          SizedBox(
            width: responsiveDimension(150),
            child: AppButton(
              label: 'common.add'.tr(),
              size: AppButtonSize.small,
              variant: AppButtonVariant.outline,
              icon: const Icon(Icons.add),
              iconPosition: AppButtonIconPosition.left,
              onPressed: _openAddAreaPicker,
            ),
          ),
        ],
      ),
    );
  }
}

/// Resolves a location [failure] to a localized message by its stable code,
/// so the raw platform exception text is never shown to the user (SAN-778).
String _localizedFailure(Failure failure) => switch (failure.code) {
  LocationFailureCodes.serviceDisabled =>
    'branches.location_picker.service_disabled'.tr(),
  LocationFailureCodes.permissionDenied =>
    'branches.location_picker.permission_denied'.tr(),
  LocationFailureCodes.permissionPermanentlyDenied =>
    'branches.location_picker.permission_denied'.tr(),
  LocationFailureCodes.outsideSupportedCountry =>
    'branches.location_picker.outside_uae'.tr(),
  _ => 'branches.location_picker.generic_error'.tr(),
};
