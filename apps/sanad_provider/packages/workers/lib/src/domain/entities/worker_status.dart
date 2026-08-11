/// Worker account state as defined by the backend (`active` | `inactive`).
///
/// The UI surfaces "suspend"/"unsuspend" actions, which map to `inactive`
/// and `active` respectively — there is no separate `suspended` state on the
/// backend, and `pending` belongs to invitations, not workers.
enum WorkerStatus {
  active,
  inactive
  ;

  static WorkerStatus fromString(String? value) =>
      switch (value?.toLowerCase()) {
        'active' => WorkerStatus.active,
        'inactive' => WorkerStatus.inactive,
        _ => WorkerStatus.inactive,
      };

  /// Serialized value for `UpdateWorkerStatusDto` / `UpdateWorkerDto`.
  String toApiValue() => name;
}
