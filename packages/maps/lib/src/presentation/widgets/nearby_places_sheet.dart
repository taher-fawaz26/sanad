import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class NearbyPlacesSheet extends StatelessWidget {
  const NearbyPlacesSheet({
    required this.title,
    required this.places,
    this.onPlaceSelected,
    this.onPlaceRemoved,
    this.emptyMessage,
    super.key,
  });

  final String title;
  final List<String> places;
  final ValueChanged<String>? onPlaceSelected;
  final ValueChanged<String>? onPlaceRemoved;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            title,
            style: typography.regularNormal.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (places.isEmpty)
          Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Text(
              emptyMessage ?? '',
              style: typography.smallNormal.copyWith(
                color: colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: places.length,
            itemBuilder: (context, index) {
              final place = places[index];
              return ListTile(
                dense: true,
                leading: Icon(
                  Icons.place_outlined,
                  color: colors.onSurfaceVariant,
                  size: responsiveDimension(20),
                ),
                title: Text(
                  place,
                  style: typography.regularNormal,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: onPlaceSelected != null
                    ? () => onPlaceSelected!(place)
                    : null,
                trailing: onPlaceRemoved != null
                    ? IconButton(
                        icon: Icon(
                          Icons.close,
                          size: responsiveDimension(18),
                          color: colors.onSurfaceVariant,
                        ),
                        onPressed: () => onPlaceRemoved!(place),
                      )
                    : null,
              );
            },
          ),
      ],
    );
  }
}
