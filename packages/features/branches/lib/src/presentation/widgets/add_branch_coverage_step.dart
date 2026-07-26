import 'dart:math' as math;

import 'package:branches/src/presentation/widgets/branch_pin_empty_body.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:maps/maps.dart';

/// Add/Edit branch — Step 2 coverage (Figma `1563:10977` / `1563:10978`).
///
/// Shows the map-pin "Add Branch Coverage" prompt only while no coverage exists
/// yet (first time in create). Once coverage has been set — always in edit, and
/// in create after it was set / when navigating back — it shows a preview of
/// the coverage area (map + radius + serving areas) instead of the prompt. In
/// both states tapping opens the map picker (seeded with the current values).
class AddBranchCoverageStep extends StatelessWidget {
  const AddBranchCoverageStep({
    required this.onEditCoverage,
    this.position,
    this.radiusKm,
    this.address,
    this.areaNames = const [],
    super.key,
  });

  /// Opens the coverage area map picker to add or edit coverage.
  final VoidCallback onEditCoverage;

  /// Current coverage centre, when set.
  final LatLng? position;

  /// Current coverage radius (km), when set.
  final double? radiusKm;

  /// Reverse-geocoded address of the coverage centre, when available.
  final String? address;

  /// Names of the serving areas within the coverage.
  final List<String> areaNames;

  bool get _hasCoverage => position != null && radiusKm != null;

  @override
  Widget build(BuildContext context) {
    if (_hasCoverage) {
      return _CoverageSetContent(
        position: position!,
        radiusKm: radiusKm!,
        address: address,
        areaNames: areaNames,
        onEditCoverage: onEditCoverage,
      );
    }

    return GestureDetector(
      onTap: onEditCoverage,
      behavior: HitTestBehavior.opaque,
      child: BranchPinEmptyBody(
        title: 'branches.add_branch.coverage_title'.tr(),
        description: 'branches.add_branch.coverage_description'.tr(),
      ),
    );
  }
}

/// Filled coverage state — a non-interactive map preview (centre marker +
/// radius circle), the radius, the serving-area chips, and an edit button.
class _CoverageSetContent extends StatelessWidget {
  const _CoverageSetContent({
    required this.position,
    required this.radiusKm,
    required this.areaNames,
    required this.onEditCoverage,
    this.address,
  });

  final LatLng position;
  final double radiusKm;
  final String? address;
  final List<String> areaNames;
  final VoidCallback onEditCoverage;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'branches.add_branch.coverage_set_title'.tr(),
            style: typography
                .semiBold(typography.smallTight)
                .copyWith(color: colors.textMuted),
          ),
          SizedBox(height: AppSpacing.md),
          GestureDetector(
            onTap: onEditCoverage,
            behavior: HitTestBehavior.opaque,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: responsiveDimension(200),
                child: AbsorbPointer(
                  child: AppGoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: position,
                      zoom: _zoomForRadius(radiusKm),
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('coverage-preview'),
                        position: position,
                      ),
                    },
                    circles: {
                      Circle(
                        circleId: const CircleId('coverage-preview'),
                        center: position,
                        radius: radiusKm * 1000,
                        fillColor: colors.primary.withValues(alpha: 0.12),
                        strokeColor: colors.primary,
                        strokeWidth: 2,
                      ),
                    },
                    scrollGesturesEnabled: false,
                    zoomGesturesEnabled: false,
                    tiltGesturesEnabled: false,
                    rotateGesturesEnabled: false,
                    compassEnabled: false,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                Icons.trip_origin,
                size: 16,
                color: colors.primary,
              ),
              SizedBox(width: AppSpacing.xs),
              Text(
                'branches.details.radius_km'.tr(
                  namedArgs: {'radius': _formatRadius(radiusKm)},
                ),
                style: typography.regularNormal.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          if (address != null && address!.isNotEmpty) ...[
            SizedBox(height: AppSpacing.xs),
            Text(
              address!,
              style: typography.smallNormal.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
          if (areaNames.isNotEmpty) ...[
            SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final area in areaNames)
                  AppChip(
                    label: area,
                    tone: AppChipTone.softSuccess,
                    icon: Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: colors.palettes.main.shade700,
                    ),
                    iconPosition: AppChipIconPosition.left,
                  ),
              ],
            ),
          ],
          SizedBox(height: AppSpacing.lg),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppButtonPresets.outline(
              label: 'branches.add_branch.edit_coverage_button'.tr(),
              size: AppButtonSize.large,
              icon: const Icon(Icons.edit_location_alt_outlined),
              iconPosition: AppButtonIconPosition.left,
              onPressed: onEditCoverage,
            ),
          ),
        ],
      ),
    );
  }

  /// Approximate zoom that keeps the radius circle comfortably in view. Each
  /// zoom level roughly halves the visible span, so subtract log2(radiusKm).
  double _zoomForRadius(double radiusKm) {
    if (radiusKm <= 0) return 14;
    final zoom = 14 - (math.log(radiusKm) / math.ln2);
    return zoom.clamp(9.0, 16.0);
  }

  String _formatRadius(double radiusKm) {
    return radiusKm == radiusKm.roundToDouble()
        ? radiusKm.toStringAsFixed(0)
        : radiusKm.toStringAsFixed(1);
  }
}
