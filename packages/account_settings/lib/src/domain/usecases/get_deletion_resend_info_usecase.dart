import 'package:account_settings/src/domain/entities/deletion_resend_info.dart';
import 'package:account_settings/src/domain/repositories/account_deletion_repository.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

class GetDeletionResendInfoUseCase
    implements UseCase<DeletionResendInfo, NoParams> {
  const GetDeletionResendInfoUseCase(this._repository);

  final AccountDeletionRepository _repository;

  @override
  TaskEither<Failure, DeletionResendInfo> call(NoParams params) =>
      _repository.getResendInfo();
}
