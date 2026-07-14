import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapTypeButton extends StatelessWidget {
  const MapTypeButton({
    required this.currentType,
    required this.onChanged,
    super.key,
  });

  final MapType currentType;
  final ValueChanged<MapType> onChanged;

  IconData get _icon => switch (currentType) {
        MapType.normal => Icons.satellite_alt,
        MapType.satellite => Icons.map_outlined,
        MapType.terrain => Icons.map_outlined,
        MapType.hybrid => Icons.map_outlined,
        _ => Icons.layers,
      };

  MapType get _nextType => switch (currentType) {
        MapType.normal => MapType.satellite,
        _ => MapType.normal,
      };

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
      child: AppIconButton(
        icon: _icon,
        size: AppIconButtonSize.large,
        onTap: () => onChanged(_nextType),
      ),
    );
  }
}
