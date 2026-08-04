import 'package:media/src/models/edited_media.dart';

/// Optional side-effect hooks the coordinator invokes as the flow progresses.
///
/// These are for the consuming feature's observation only (analytics,
/// logging, UI nudges). Deciding what to *do* with the result — upload,
/// retry, cancel — is the feature's job via [onEditCompleted]'s payload and
/// the coordinator's returned result, not these callbacks.
class MediaLifecycleCallbacks {
  const MediaLifecycleCallbacks({
    this.onEditStarted,
    this.onEditCancelled,
    this.onEditCompleted,
    this.onViewerOpened,
    this.onViewerClosed,
  });

  /// The edit flow began (a source was chosen and the editor is opening).
  final void Function()? onEditStarted;

  /// The user backed out of the picker or editor without producing media.
  final void Function()? onEditCancelled;

  /// The user confirmed edits; carries the processed result.
  final void Function(EditedMedia media)? onEditCompleted;

  final void Function()? onViewerOpened;
  final void Function()? onViewerClosed;
}
