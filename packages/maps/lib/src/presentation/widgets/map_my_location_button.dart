import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Presentational "use my current location" (crosshair) control.
///
/// Intentionally dumb: it renders either a spinner (while a request is in
/// flight) or the crosshair icon, and delegates the tap upward. The whole
/// current-location sequence — permission/service resolution, GPS fetch,
/// supported-area validation, camera move, reverse-geocode, retry and
/// lifecycle recovery — lives in `LocationPickerBloc` so there is a single
/// state machine and one in-flight guard (SAN-778).
class MapMyLocationButton extends StatelessWidget {
  const MapMyLocationButton({
    required this.isLoading,
    required this.onPressed,
    super.key,
  });

  /// Whether a current-location request is currently running. Renders the
  /// spinner and (via the bloc's own guard) makes repeated taps no-ops.
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(
          responsiveDimension(8),
        ),
        boxShadow: AppShadows.small,
      ),
      child: isLoading
          ? const AppLoadingIndicator(size: 40)
          : AppIconButton(
              icon: Icons.my_location,
              size: AppIconButtonSize.large,
              onTap: onPressed,
              semanticLabel: 'Go to my location',
            ),
    );
  }
}
