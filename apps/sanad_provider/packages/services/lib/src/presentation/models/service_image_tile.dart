import 'package:equatable/equatable.dart';
import 'package:shared_ui/shared_ui.dart';

/// One tile rendered by [ServiceImagesEditor] — pairs the generic
/// [MediaUploadTileData] with the two flags that differ between Add and
/// Edit mode: which tile (if any) is "Main", and whether a mutation is in
/// flight for it. Both are computed by the caller (positionally for Add's
/// staged images, from `ProviderServiceImageEntity.isPrimary`/
/// `ServiceImagesState.busyImageId` for Edit's committed ones) — this type
/// carries no logic of its own.
class ServiceImageTile extends Equatable {
  const ServiceImageTile({
    required this.data,
    required this.isMain,
    this.isBusy = false,
  });

  final MediaUploadTileData data;
  final bool isMain;
  final bool isBusy;

  @override
  List<Object?> get props => [data, isMain, isBusy];
}
