import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/presentation/models/location_picker_labels.dart';
import 'package:maps/src/presentation/models/location_picker_result.dart';
import 'package:maps/src/presentation/models/map_configuration.dart';
import 'package:maps/src/presentation/widgets/map_location_picker.dart';

Future<LocationPickerResult?> showLocationPickerSheet(
  BuildContext context, {
  required LocationPickerLabels labels,
  LatLng? initialPosition,
  String? initialAddress,
  MapConfiguration configuration = const MapConfiguration(),
  Widget? pinMarker,
}) {
  return showAppModalSheet<LocationPickerResult>(
    context: context,
    child: Builder(
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: MapLocationPicker(
          labels: labels,
          initialPosition: initialPosition,
          initialAddress: initialAddress,
          configuration: configuration,
          pinMarker: pinMarker,
          onConfirmed: (result) => Navigator.of(sheetContext).pop(result),
        ),
      ),
    ),
  );
}
