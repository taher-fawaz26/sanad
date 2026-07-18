enum BranchWorkerType {
  worker,
  manager
  ;

  String toApiString() => switch (this) {
    BranchWorkerType.worker => 'worker',
    BranchWorkerType.manager => 'manager',
  };

  static BranchWorkerType fromApiString(String? value) =>
      value == 'manager' ? BranchWorkerType.manager : BranchWorkerType.worker;
}
