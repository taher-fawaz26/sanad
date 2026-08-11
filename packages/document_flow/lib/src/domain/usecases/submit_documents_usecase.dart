import 'package:core/core.dart';
import 'package:document_flow/src/domain/repositories/document_flow_repository.dart';
import 'package:document_flow/src/domain/usecases/document_flow_params.dart';
import 'package:fpdart/fpdart.dart';

class SubmitDocumentsUseCase implements UseCase<Unit, SubmitParams> {
  SubmitDocumentsUseCase(this._repository);

  final DocumentFlowRepository _repository;

  @override
  TaskEither<Failure, Unit> call(SubmitParams params) =>
      _repository.submit(params);
}
