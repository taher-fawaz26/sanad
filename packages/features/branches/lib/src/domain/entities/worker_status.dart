enum WorkerStatus {
  active,
  inactive
  ;

  String toApiString() => switch (this) {
    WorkerStatus.active => 'active',
    WorkerStatus.inactive => 'inactive',
  };

  static WorkerStatus fromApiString(String? value) =>
      value == 'inactive' ? WorkerStatus.inactive : WorkerStatus.active;
}
