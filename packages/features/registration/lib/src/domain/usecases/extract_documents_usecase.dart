import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:registration/src/data/models/extraction_result.dart';
import 'package:registration/src/domain/repositories/media_repository.dart';

class ExtractDocumentsParams extends Equatable {
  const ExtractDocumentsParams({
    required this.authorizationToken,
    required this.emiratesIdFrontId,
    required this.emiratesIdBackId,
    this.tradeLicenseId,
  });

  final String authorizationToken;
  final String emiratesIdFrontId;
  final String emiratesIdBackId;
  final String? tradeLicenseId;

  @override
  List<Object?> get props => [
        authorizationToken,
        emiratesIdFrontId,
        emiratesIdBackId,
        tradeLicenseId,
      ];
}

/// Calls `POST auth/extract` with the uploaded document IDs.
class ExtractDocumentsUseCase
    implements UseCase<ExtractionResult, ExtractDocumentsParams> {
  const ExtractDocumentsUseCase(this._repository);

  final MediaRepository _repository;

  @override
  TaskEither<Failure, ExtractionResult> call(ExtractDocumentsParams params) =>
      _repository.extractDocuments(
        authorizationToken: params.authorizationToken,
        emiratesIdFrontId: params.emiratesIdFrontId,
        emiratesIdBackId: params.emiratesIdBackId,
        tradeLicenseId: params.tradeLicenseId,
      );
}
