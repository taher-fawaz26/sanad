enum WorkerStatus {
  active,
  pending,
  suspended
  ;

  static WorkerStatus fromString(String? value) =>
      switch (value?.toLowerCase()) {
        'active' => WorkerStatus.active,
        'pending' => WorkerStatus.pending,
        'suspended' => WorkerStatus.suspended,
        _ => WorkerStatus.pending,
      };
}
