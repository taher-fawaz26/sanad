/// The high-level kind of media this toolkit handles.
///
/// Only [image] is supported today. [video] exists so the picker, validation,
/// and result types can be extended for video without a breaking API change —
/// the coordinator branches on the picked type and routes to the appropriate
/// editor/viewer.
enum MediaType {
  image,
  video;

  bool get isImage => this == MediaType.image;

  bool get isVideo => this == MediaType.video;
}
