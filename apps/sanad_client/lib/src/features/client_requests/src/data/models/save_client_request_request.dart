import 'package:requests_core/requests_core.dart';

/// The body shared by `POST /requests` (create a draft) and
/// `PATCH /requests/:id` (edit one) — the contract defines the same optional
/// fields for both.
///
/// **Every field is optional and omitted when unset.** That is what makes a
/// partial draft saveable: sending `null` for an unfilled field would clear a
/// value the user had already entered on an earlier save, and sending the whole
/// shape would invite submit-time validation at draft time.
///
/// The one exception is [mediaIds], which the backend documents as replacing
/// the whole set — so it is sent whenever the caller supplies it, including as
/// an empty list to detach everything.
class SaveClientRequestRequest {
  /// Creates a save body. Every field is optional.
  const SaveClientRequestRequest({
    this.serviceId,
    this.lat,
    this.lng,
    this.addressLine,
    this.preferredAt,
    this.note,
    this.mediaIds,
  });

  /// Catalogue service id.
  final String? serviceId;

  /// Job latitude.
  final double? lat;

  /// Job longitude.
  final double? lng;

  /// Street address entered by the client.
  final String? addressLine;

  /// Serialized with an explicit offset — a naive local string is read as UTC
  /// and lands hours out. See [ApiDateTime].
  final DateTime? preferredAt;

  /// The client's description of the job.
  final String? note;

  /// Replaces the whole attachment set when non-null. At most
  /// [RequestFieldLimits.maxMediaIds].
  final List<String>? mediaIds;

  /// Serializes only the fields that were set.
  Map<String, dynamic> toJson() {
    final trimmedAddress = addressLine?.trim();
    final trimmedNote = note?.trim();
    return {
      if (serviceId != null) 'serviceId': serviceId,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (trimmedAddress != null && trimmedAddress.isNotEmpty)
        'addressLine': trimmedAddress,
      if (preferredAt != null) 'preferredAt': ApiDateTime.encode(preferredAt!),
      if (trimmedNote != null && trimmedNote.isNotEmpty) 'note': trimmedNote,
      if (mediaIds != null) 'mediaIds': mediaIds,
    };
  }
}
