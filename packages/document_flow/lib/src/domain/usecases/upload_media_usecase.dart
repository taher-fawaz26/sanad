import 'package:core/core.dart';
import 'package:document_flow/src/domain/entities/document_media.dart';
import 'package:document_flow/src/domain/repositories/document_flow_repository.dart';
import 'package:document_flow/src/domain/usecases/document_flow_params.dart';
import 'package:fpdart/fpdart.dart';

class UploadMediaUseCase implements UseCase<DocumentMedia, UploadMediaParams> {
  UploadMediaUseCase(this._repository);

  final DocumentFlowRepository _repository;

  @override
  TaskEither<Failure, DocumentMedia> call(UploadMediaParams params) =>
      _repository.uploadMedia(params);

  void cancel(String uploadKey) => _repository.cancelUpload(uploadKey);
}
