import 'package:app_assets/app_assets.dart';
import 'package:branches/src/presentation/models/coverage_area_result.dart';
import 'package:branches/src/presentation/utils/branch_map_defaults.dart';
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

  final _radiusDebouncer =
      Debouncer(delay: const Duration(milliseconds: 400));
  final _radiusController = MapRadiusController();
  GoogleMapController? _mapController;
  double? _previewRadiusKm;
  bool _isDragging = false;

  @override
  void dispose() {
    _radiusDebouncer.dispose();
    _radiusController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _animateTo(LatLng position) async {
    final controller = _mapController;
    if (controller == null) return;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: position,
          zoom: BranchMapDefaults.coverageZoom,
        ),
      ),
    );
  }

  void _onCameraMove(CameraPosition position) {
    if (!_isDragging) {
      setState(() => _isDragging = true);
    }
  }

  void _onCameraIdle() {
    if (!_isDragging) return;
    setState(() => _isDragging = false);
    final controller = _mapController;
    if (controller == null) return;
    controller.getVisibleRegion().then((bounds) {
      if (!mounted) return;
      final center = LatLng(
        (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
        (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
      );
      context.read<CoverageAreaBloc>().add(
        CoverageAreaCameraIdle(center),
      );
    });
  }

  Future<void> _openServingAreaSearch() async {
    await showServingAreaSearchSheet(
      context,
      labels: ServingAreaSearchLabels(
        title: 'branches.coverage_area.add_serving_area'.tr(),
        searchHint:
            'branches.coverage_area.search_serving_area'.tr(),
        noResultsMessage:
            'branches.coverage_area.no_areas_found'.tr(),
        genericError:
            'branches.coverage_area.search_error'.tr(),
        confirm: 'branches.coverage_area.done'.tr(),
      ),
    );
  }

  void _confirm(CoverageAreaState state) {
    final position = state.position;
    final address = state.address;
    if (position == null || address == null) return;

    context.pop(
      CoverageAreaResult(
        position: position,
        address: address,
        radiusKm: state.radiusKm,
        servingAreas: state.servingAreas,
      ),
    );
  }

  void _syncRadiusController(CoverageAreaState state) {
    _radiusController.update(
      center: state.position,
      radiusKm: _previewRadiusKm ?? state.radiusKm,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CoverageAreaBloc, CoverageAreaState>(
      listenWhen: (previous, current) =>
          previous.position != current.position ||
          previous.cameraSource != current.cameraSource ||
          previous.radiusKm != current.radiusKm,
      listener: (context, state) {
        if (state.cameraSource ==
                CoverageAreaCameraSource.programmatic &&
            state.position != null) {
          _animateTo(state.position!);
        }
        final preview = _previewRadiusKm;
        if (preview != null &&
            (preview - state.radiusKm).abs() <
                _radiusSnapThresholdKm) {
          setState(() => _previewRadiusKm = null);
        }
      },
      builder: (context, state) {
        _syncRadiusController(state);
        final mapTarget =
            state.position ?? BranchMapDefaults.position;
        final displayRadiusKm =
            _previewRadiusKm ?? state.radiusKm;

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
                    padding:
                        EdgeInsets.only(bottom: AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [
                        AppSection(
                          title: 'branches.coverage_area.title'
                              .tr(),
                          caption:
                              'branches.coverage_area.subtitle'
                                  .tr(),
                        ),
                        SizedBox(height: AppSpacing.md),
                        _buildMap(context, state, mapTarget),
                        SizedBox(height: AppSpacing.md),
                        _buildRadiusSection(
                          context,
                          state,
                          displayRadiusKm,
                        ),
                        SizedBox(height: AppSpacing.md),
                        _buildServingAreasSection(
                          context,
                          state,
                        ),
                        if (state.failure != null) ...[
                          SizedBox(height: AppSpacing.sm),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl,
                            ),
                            child: Text(
                              state.failure!.message,
                              style: context
                                  .appTypography.smallNormal
                                  .copyWith(
                                    color:
                                        context.appColors.error,
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
                    label:
                        'branches.coverage_area.confirm'.tr(),
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
                  _mapController = controller;
                  if (state.position != null) {
                    _animateTo(state.position!);
                  }
                },
                onCameraMove: _onCameraMove,
                onCameraIdle: _onCameraIdle,
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
                  color: context.appColors.surface
                      .withValues(alpha: _mapOverlayAlpha),
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
              style:
                  context.appTypography.regularNormal.copyWith(
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSection(
            title:
                'branches.coverage_area.covered_areas'.tr(),
            size: AppSectionSize.compact,
            trailing: AppSectionTrailing.custom,
            trailingWidget: Text(
              'branches.coverage_area.areas_count'.tr(
                namedArgs: {
                  'count': '${state.servingAreas.length}',
                },
              ),
              style:
                  context.appTypography.regularNormal.copyWith(
                fontWeight: FontWeight.w500,
                color: context.appColors.textPrimary,
              ),
            ),
            padding: EdgeInsets.zero,
          ),
          SizedBox(height: AppSpacing.sm),
          ServingAreaChips(
            areas: state.servingAreas,
            emptyMessage:
                'branches.coverage_area.no_areas_message'.tr(),
            onRemoved: (area) {
              context.read<CoverageAreaBloc>().add(
                CoverageAreaServingAreaRemoved(area.placeId),
              );
            },
          ),
          SizedBox(height: AppSpacing.sm),
          AppChip(
            label:
                'branches.coverage_area.add_area'.tr(),
            selected: true,
            iconPosition: AppChipIconPosition.left,
            icon: Icon(
              Icons.add,
              size: AppDimension.iconCompact,
              color: context.appColors.onPrimary,
            ),
            onTap: _openServingAreaSearch,
          ),
        ],
      ),
    );
  }
}
