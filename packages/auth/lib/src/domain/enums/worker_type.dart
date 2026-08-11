enum WorkerType {
  worker('worker'),
  manager('manager')
  ;

  const WorkerType(this.value);
  final String value;

  static WorkerType fromString(String value) {
    return WorkerType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Unknown WorkerType: $value'),
    );
  }

  static String toJson(WorkerType value) {
    return value.value;
  }

  static WorkerType fromJson(String value) {
    return fromString(value);
  }
}
