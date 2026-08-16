/// Maximum images a provider service may carry — matches the backend's
/// "image limit of six reached" rule (`POST /provider-services/:id/images`)
/// and `CreateProviderServiceDto.imageIds` (minItems 1, maxItems 6). Single
/// source of truth for both Add Service (`MediaUploadConfig.maxFiles`) and
/// Edit Service (`ServiceImagesEditor.maxImages`).
const int kMaxServiceImages = 6;
