/// Sanad Media Upload — feature-agnostic pick → validate → upload → progress
/// pipeline. Sits on top of `asset_picker` and beneath every feature's own
/// attach/replace business logic.
///
/// This package must remain feature-independent: it knows nothing about
/// registration, organization settings, products, or any other business
/// entity — it only produces an `UploadedMedia` with a `mediaId` that callers
/// use for their own follow-up API calls.
library;

export 'src/di/media_upload_di.dart';
export 'src/domain/entities/media_upload_config.dart';
export 'src/domain/entities/media_upload_item.dart';
export 'src/domain/entities/media_upload_status.dart';
export 'src/domain/entities/uploaded_media.dart';
export 'src/domain/failures/media_upload_failure.dart';
export 'src/domain/repositories/media_upload_repository.dart';
export 'src/domain/validators/media_upload_validator.dart';
export 'src/presentation/bloc/media_upload_bloc.dart';
