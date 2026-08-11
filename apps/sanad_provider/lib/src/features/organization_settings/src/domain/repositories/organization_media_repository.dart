import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:media/media.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/organization_media_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/organization_media_slot.dart';

/// Uploads/removes the organization's identity images. Owned by the feature —
/// the generic `media` package never uploads.
abstract interface class OrganizationMediaRepository {
  TaskEither<Failure, OrganizationMediaEntity> uploadMedia({
    required OrganizationMediaSlot slot,
    required EditedMedia media,
    void Function(double progress)? onProgress,
  });

  TaskEither<Failure, Unit> removeMedia({required OrganizationMediaSlot slot});

  /// Cancels an in-flight upload for [slot].
  void cancelUpload(OrganizationMediaSlot slot);
}
