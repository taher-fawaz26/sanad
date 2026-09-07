part of 'assign_branch_bloc.dart';

class AssignBranchState extends Equatable {
  const AssignBranchState({
    this.loadStatus = RequestStatus.initial,
    this.branches = const [],
    this.loadFailure,
    this.selectedBranch,
    this.saveStatus = RequestStatus.initial,
    this.saveFailure,
    this.updatedWorker,
  });

  final RequestStatus loadStatus;
  final List<BranchEntity> branches;
  final Failure? loadFailure;

  final BranchEntity? selectedBranch;

  final RequestStatus saveStatus;
  final Failure? saveFailure;

  /// Set alongside [saveStatus] = success — the sheet reads it from a
  /// [BlocListener] to invoke the caller's `onWorkerUpdated` and pop.
  final WorkerEntity? updatedWorker;

  bool get isLoading => loadStatus == RequestStatus.loading;
  bool get isSaving => saveStatus == RequestStatus.loading;
  bool get canSubmit => selectedBranch != null && !isSaving;

  AssignBranchState copyWith({
    RequestStatus? loadStatus,
    List<BranchEntity>? branches,
    Failure? loadFailure,
    bool clearLoadFailure = false,
    BranchEntity? selectedBranch,
    RequestStatus? saveStatus,
    Failure? saveFailure,
    bool clearSaveFailure = false,
    WorkerEntity? updatedWorker,
  }) => AssignBranchState(
    loadStatus: loadStatus ?? this.loadStatus,
    branches: branches ?? this.branches,
    loadFailure: clearLoadFailure ? null : (loadFailure ?? this.loadFailure),
    selectedBranch: selectedBranch ?? this.selectedBranch,
    saveStatus: saveStatus ?? this.saveStatus,
    saveFailure: clearSaveFailure ? null : (saveFailure ?? this.saveFailure),
    updatedWorker: updatedWorker ?? this.updatedWorker,
  );

  @override
  List<Object?> get props => [
    loadStatus,
    branches,
    loadFailure,
    selectedBranch,
    saveStatus,
    saveFailure,
    updatedWorker,
  ];
}
