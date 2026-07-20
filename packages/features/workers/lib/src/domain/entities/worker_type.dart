enum WorkerType {
  worker,
  manager
  ;

  String toApiString() => name;

  static WorkerType fromApiString(String? value) =>
      value == 'manager' ? WorkerType.manager : WorkerType.worker;
}
