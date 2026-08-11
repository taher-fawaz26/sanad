enum WorkerStatus {
  active('active'),
  inactive('inactive'),
  ;

  const WorkerStatus(this.value);
  final String value;

  static WorkerStatus fromString(String value) {
    return WorkerStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Unknown WorkerStatus: $value'),
    );
  }

  static String toJson(WorkerStatus value) {
    return value.value;
  }

  static WorkerStatus fromJson(String value) {
    return fromString(value);
  }
}
