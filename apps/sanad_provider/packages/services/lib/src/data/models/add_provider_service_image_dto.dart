/// `AddProviderServiceImageDto` — POST
/// /provider-services/:id/images request body.
class AddProviderServiceImageDto {
  const AddProviderServiceImageDto({required this.mediaId});

  final String mediaId;

  Map<String, dynamic> toJson() => {'mediaId': mediaId};
}
