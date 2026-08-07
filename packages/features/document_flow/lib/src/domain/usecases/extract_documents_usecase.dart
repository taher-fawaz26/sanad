import 'package:core/core.dart';
import 'package:document_flow/src/domain/entities/extracted_document.dart';
import 'package:document_flow/src/domain/repositories/document_flow_repository.dart';
import 'package:document_flow/src/domain/usecases/document_flow_params.dart';
import 'package:fpdart/fpdart.dart';

class ExtractDocumentsUseCase
    implements UseCase<ExtractedDocuments, ExtractParams> {
  ExtractDocumentsUseCase(this._repository);

  final DocumentFlowRepository _repository;

  @override
  TaskEither<Failure, ExtractedDocuments> call(ExtractParams params) =>
      _repository.extract(params);
}
