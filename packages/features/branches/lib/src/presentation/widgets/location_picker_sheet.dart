import 'package:app_assets/app_assets.dart';
import 'package:branches/src/presentation/bloc/location_picker/location_picker_bloc.dart';
import 'package:branches/src/presentation/models/location_picker_result.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maps/maps.dart';

/// Opens the Figma location-picker bottom sheet (`365:14741`).
Future<LocationPickerResult?> showLocationPickerSheet(BuildContext context) {
  return showAppBottomSheet<LocationPickerResult>(
    context: context,
    showDragHandle: false,
    child: BlocProvider(
      create: (_) =>
          sl<LocationPickerBloc>()..add(const LocationPickerStarted()),
      child: const _LocationPickerSheet(),
    ),
  );
}

class _LocationPickerSheet extends StatefulWidget {
  const _LocationPickerSheet();

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  static const _defaultPosition = LatLng(25.0772, 55.1396);
  static const _defaultZoom = 14.0;

  final _searchController = TextEditingController();
  GoogleMapController? _mapController;
  LatLng? _trackedCameraPosition;
  bool _isAnimatingCamera = false;

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _animateTo(LatLng position) async {
    final controller = _mapController;
    if (controller == null) return;

    _isAnimatingCamera = true;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: position, zoom: _defaultZoom),
      ),
    );
    _isAnimatingCamera = false;
    _trackedCameraPosition = position;
  }

  void _onCameraMove(CameraPosition position) {
    _trackedCameraPosition = position.target;
  }

  void _onCameraIdle() {
    if (_isAnimatingCamera) return;
    final target = _trackedCameraPosition;
    if (target == null) return;
    context.read<LocationPickerBloc>().add(
      LocationPickerCameraIdle(target),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LocationPickerBloc, LocationPickerState>(
      listenWhen: (previous, current) =>
          previous.position != current.position ||
          previous.cameraSource != current.cameraSource,
      listener: (context, state) {
        if (state.cameraSource == LocationPickerCameraSource.programmatic &&
            state.position != null) {
          _animateTo(state.position!);
        }
      },
      builder: (context, state) {
        final initialPosition = state.position ?? _defaultPosition;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSearchField(
              controller: _searchController,
              hint: 'branches.location_picker.search_hint'.tr(),
              showMicIcon: false,
              onSubmitted: (query) {
                context.read<LocationPickerBloc>().add(
                  LocationPickerSearchSubmitted(query),
                );
              },
            ),
            SizedBox(height: AppSpacing.md),
            SizedBox(
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
                        target: initialPosition,
                        zoom: _defaultZoom,
                      ),
                      onMapCreated: (controller) {
                        _mapController = controller;
                        _trackedCameraPosition = initialPosition;
                        if (state.position != null) {
                          _animateTo(state.position!);
                        }
                      },
                      onCameraMove: _onCameraMove,
                      onCameraIdle: _onCameraIdle,
                      myLocationEnabled: state.position != null,
                      zoomControlsEnabled: false,
                    ),
                    IgnorePointer(
                      child: Icon(
                        Icons.location_on,
                        size: responsiveDimension(40),
                        color: context.appColors.error,
                      ),
                    ),
                    if (state.isLoadingMap)
                      ColoredBox(
                        color: context.appColors.surface.withValues(
                          alpha: 0.6,
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    if (state.isGeocoding && !state.isLoadingMap)
                      Positioned(
                        top: AppSpacing.sm,
                        right: AppSpacing.sm,
                        child: const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: AppSpacing.md),
            if (state.hasPermissionError)
              _PermissionMessage(state: state)
            else if (state.status == LocationPickerStatus.failure)
              _ErrorMessage(failure: state.failure)
            else
              _LocationAddressField(
                label: 'branches.location_picker.specified_location'.tr(),
                value: state.address,
                hint: 'branches.location_picker.address_hint'.tr(),
              ),
            SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'branches.location_picker.confirm'.tr(),
              onPressed: state.canConfirm
                  ? () {
                      final position = state.position;
                      final address = state.address;
                      if (position == null || address == null) return;
                      Navigator.of(context).pop(
                        LocationPickerResult(
                          position: position,
                          address: address,
                        ),
                      );
                    }
                  : null,
            ),
          ],
        );
      },
    );
  }
}

class _LocationAddressField extends StatelessWidget {
  const _LocationAddressField({
    required this.label,
    required this.hint,
    this.value,
  });

  final String label;
  final String? value;
  final String hint;

  bool get _hasValue => value != null && value!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final brightness = Theme.of(context).brightness;
    final fieldHeight = responsiveDimension(80);
    final labelGap = responsiveDimension(FieldTokens.labelGap);
    final iconSize = AppDimension.iconLg;

    final displayStyle = _hasValue
        ? FieldTokens.valueStyle(
            typography,
            colors,
            brightness,
            enabled: true,
          )
        : FieldTokens.hintStyle(
            typography,
            colors,
            brightness,
            enabled: true,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: FieldTokens.labelStyle(typography, colors, brightness),
        ),
        SizedBox(height: labelGap),
        Material(
          color: FieldTokens.background(colors, brightness, enabled: true),
          shape: RoundedRectangleBorder(
            borderRadius: FieldTokens.borderRadiusAll(),
            side: BorderSide(
              color: FieldTokens.borderDefault(colors, brightness),
              width: responsiveDimension(FieldTokens.borderWidthDefault),
            ),
          ),
          child: SizedBox(
            height: fieldHeight,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsiveDimension(FieldTokens.horizontalPadding),
                vertical: responsiveDimension(FieldTokens.verticalPadding),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSvgPicture.asset(
                    AppSvgs.map,
                    width: iconSize,
                    height: iconSize,
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      _hasValue ? value! : hint,
                      style: displayStyle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PermissionMessage extends StatelessWidget {
  const _PermissionMessage({required this.state});

  final LocationPickerState state;

  @override
  Widget build(BuildContext context) {
    final message = switch (state.status) {
      LocationPickerStatus.permissionDenied =>
        'branches.location_picker.permission_denied'.tr(),
      LocationPickerStatus.permissionPermanentlyDenied =>
        'branches.location_picker.permission_permanently_denied'.tr(),
      LocationPickerStatus.serviceDisabled =>
        'branches.location_picker.service_disabled'.tr(),
      _ => 'branches.location_picker.generic_error'.tr(),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          message,
          style: context.appTypography.regularNormal.copyWith(
            color: context.appColors.error,
          ),
        ),
        if (state.status ==
            LocationPickerStatus.permissionPermanentlyDenied) ...[
          SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'branches.location_picker.open_settings'.tr(),
            type: AppButtonType.secondary,
            onPressed: () {
              context.read<LocationPickerBloc>().add(
                const LocationPickerSettingsRequested(),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({this.failure});

  final Failure? failure;

  @override
  Widget build(BuildContext context) {
    return Text(
      failure?.message ?? 'branches.location_picker.generic_error'.tr(),
      style: context.appTypography.regularNormal.copyWith(
        color: context.appColors.error,
      ),
    );
  }
}
