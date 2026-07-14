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

  final _searchController = TextEditingController();
  final _radiusDebouncer = Debouncer(delay: const Duration(milliseconds: 400));
  final _radiusController = MapRadiusController();
  GoogleMapController? _mapController;
  double? _previewRadiusKm;

  @override
  void dispose() {
    _radiusDebouncer.dispose();
    _searchController.dispose();
    _radiusController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _animateTo(LatLng position) async {
    final controller = _mapController;
    if (controller == null) return;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: position, zoom: BranchMapDefaults.coverageZoom),
      ),
    );
  }

  Future<void> _openLocationPicker() async {
    final state = context.read<CoverageAreaBloc>().state;
    final result = await showLocationPickerSheet(
      context,
      labels: LocationPickerLabels(
        searchHint: 'branches.location_picker.search_hint'.tr(),
        confirm: 'branches.location_picker.confirm'.tr(),
        specifiedLocation:
            'branches.location_picker.specified_location'.tr(),
        addressHint: 'branches.location_picker.address_hint'.tr(),
        permissionDenied:
            'branches.location_picker.permission_denied'.tr(),
        permissionPermanentlyDenied: 'branches.location_picker'
            '.permission_permanently_denied'
            .tr(),
        serviceDisabled:
            'branches.location_picker.service_disabled'.tr(),
        genericError: 'branches.location_picker.generic_error'.tr(),
        openSettings: 'branches.location_picker.open_settings'.tr(),
      ),
      initialPosition: state.position,
      initialAddress: state.address,
    );
    if (!mounted || result == null) return;

    context.read<CoverageAreaBloc>().add(
      CoverageAreaLocationUpdated(
        position: result.position,
        address: result.address,
      ),
    );
  }

  Future<void> _openAddAreaDialog() async {
    final controller = TextEditingController();
    final area = await showAppDialog<String>(
      context: context,
      title: 'branches.coverage_area.add_area_title'.tr(),
      actions: AppPopoverActions.textInput,
      textFieldController: controller,
      textFieldHint: 'branches.coverage_area.add_area_hint'.tr(),
      primaryLabel: 'branches.coverage_area.add_area'.tr(),
      secondaryLabel: 'branches.add_branch.cancel'.tr(),
      onPrimary: () => Navigator.of(context).pop(controller.text.trim()),
      onSecondary: () => Navigator.of(context).pop(),
    );
    controller.dispose();
    if (!mounted || area == null || area.isEmpty) return;

    context.read<CoverageAreaBloc>().add(CoverageAreaAreaAdded(area));
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
        coveredAreas: state.coveredAreas,
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
        if (state.cameraSource == CoverageAreaCameraSource.programmatic &&
            state.position != null) {
          _animateTo(state.position!);
        }
        final preview = _previewRadiusKm;
        if (preview != null &&
            (preview - state.radiusKm).abs() < _radiusSnapThresholdKm) {
          setState(() => _previewRadiusKm = null);
        }
      },
      builder: (context, state) {
        _syncRadiusController(state);
        final mapTarget = state.position ?? BranchMapDefaults.position;
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
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                          ),
                          child: AppSearchField(
                            controller: _searchController,
                            hint: 'branches.location_picker.search_hint'.tr(),
                            showMicIcon: false,
                            onSubmitted: (query) {
                              context.read<CoverageAreaBloc>().add(
                                CoverageAreaSearchSubmitted(query),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: AppSpacing.md),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
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
                                    onTap: (_) => _openLocationPicker(),
                                    scrollGesturesEnabled: false,
                                    zoomGesturesEnabled: false,
                                    tiltGesturesEnabled: false,
                                    rotateGesturesEnabled: false,
                                  ),
                                  IgnorePointer(
                                    child: AppSvgPicture.asset(
                                      AppSvgs.mapPinMarker,
                                      width: responsiveDimension(24),
                                      height: responsiveDimension(32),
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
                        ),
                        SizedBox(height: AppSpacing.md),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                          ),
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
                                  style: context.appTypography.regularNormal
                                      .copyWith(
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
                              SizedBox(height: AppSpacing.md),
                              AppSection(
                                title: 'branches.coverage_area.covered_areas'
                                    .tr(),
                                size: AppSectionSize.compact,
                                trailing: AppSectionTrailing.custom,
                                trailingWidget: Text(
                                  'branches.coverage_area.areas_count'.tr(
                                    namedArgs: {
                                      'count': '${state.coveredAreas.length}',
                                    },
                                  ),
                                  style: context.appTypography.regularNormal
                                      .copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: context.appColors.textPrimary,
                                      ),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              SizedBox(height: AppSpacing.sm),
                              Padding(
                                padding: EdgeInsets.only(bottom: AppSpacing.md),
                                child: Wrap(
                                  spacing: AppSpacing.sm,
                                  runSpacing: AppSpacing.sm,
                                  children: [
                                    for (final area in state.coveredAreas)
                                      AppChip(
                                        label: area,
                                        style: AppChipStyle.outline,
                                        selected: true,
                                        iconPosition: AppChipIconPosition.right,
                                        icon: Icon(
                                          Icons.close,
                                          size: AppDimension.iconCompact,
                                          color: context.appColors.primary,
                                        ),
                                        onTap: () {
                                          context.read<CoverageAreaBloc>().add(
                                            CoverageAreaAreaRemoved(area),
                                          );
                                        },
                                      ),
                                    AppChip(
                                      label: 'branches.coverage_area.add_area'
                                          .tr(),
                                      selected: true,
                                      iconPosition: AppChipIconPosition.left,
                                      icon: Icon(
                                        Icons.add,
                                        size: AppDimension.iconCompact,
                                        color: context.appColors.onPrimary,
                                      ),
                                      onTap: _openAddAreaDialog,
                                    ),
                                  ],
                                ),
                              ),
                              if (state.failure != null) ...[
                                SizedBox(height: AppSpacing.sm),
                                Text(
                                  state.failure!.message,
                                  style: context.appTypography.smallNormal
                                      .copyWith(
                                        color: context.appColors.error,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
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
                    onPressed: state.canConfirm ? () => _confirm(state) : null,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
