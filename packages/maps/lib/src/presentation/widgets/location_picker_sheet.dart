import 'package:app_logger/app_logger.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/presentation/models/location_picker_labels.dart';
import 'package:maps/src/presentation/models/location_picker_result.dart';
import 'package:maps/src/presentation/models/map_configuration.dart';
import 'package:maps/src/presentation/widgets/map_location_picker.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

Future<LocationPickerResult?> showLocationPickerSheet(
  BuildContext context, {
  required LocationPickerLabels labels,
  LatLng? existingLocation,
  LatLng? initialLocation,
  String? initialAddress,
  MapConfiguration configuration = const MapConfiguration(),
  Widget? pinMarker,
}) {
  appLogger.d('[showLocationPickerSheet] opening sheet');
  return SheetNavigator.push<LocationPickerResult>(
    context,
    Builder(
      // Scrollable so locale/text-scale variance (e.g. taller Arabic line
      // heights) scrolls instead of overflowing the sheet's fixed height.
      builder: (sheetContext) => SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (labels.title != null) ...[
              Text(
                labels.title!,
                style: sheetContext.appTypography.title2.copyWith(
                  color: sheetContext.appColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (labels.subtitle != null) ...[
                SizedBox(height: AppSpacing.xs),
                Text(
                  labels.subtitle!,
                  style: sheetContext.appTypography.regularNormal.copyWith(
                    color: sheetContext.appColors.textSecondary,
                  ),
                ),
              ],
              SizedBox(height: AppSpacing.md),
            ],
            MapLocationPicker(
              labels: labels,
              existingLocation: existingLocation,
              initialLocation: initialLocation,
              initialAddress: initialAddress,
              configuration: configuration,
              pinMarker: pinMarker,
              onConfirmed: (result) => Navigator.of(sheetContext).pop(result),
            ),
          ],
        ),
      ),
    ),
    settings: const SheetRouteSettings(sheetSize: SheetSize.expanded),
  );
}
