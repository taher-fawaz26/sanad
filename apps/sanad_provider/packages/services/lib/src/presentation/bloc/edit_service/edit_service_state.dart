part of 'edit_service_bloc.dart';

class EditServiceState extends Equatable {
  const EditServiceState({
    this.status = RequestStatus.initial,
    this.updatedService,
    this.failure,
  });

  final RequestStatus status;
  final ServiceRecordEntity? updatedService;
  final Failure? failure;

  bool get isSubmitting => status == RequestStatus.loading;

  EditServiceState copyWith({
    RequestStatus? status,
    ServiceRecordEntity? updatedService,
    Failure? failure,
    bool clearFailure = false,
  }) => EditServiceState(
    status: status ?? this.status,
    updatedService: updatedService ?? this.updatedService,
    failure: clearFailure ? null : (failure ?? this.failure),
  );

  @override
  List<Object?> get props => [status, updatedService, failure];
}
