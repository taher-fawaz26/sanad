/// `DeletionCascadePreviewDto.persona` — who the deletion affects.
///
/// Server-authoritative: the client never derives persona-specific deletion
/// copy or cascade behavior from the locally signed-in role, only from this
/// value. [unknown] is the fail-safe fallback for any value the client
/// doesn't yet recognize.
enum DeletionPersona {
  admin,
  client,
  individualProvider,
  companyProvider,
  worker,
  manager,
  unknown
  ;

  static DeletionPersona fromApi(String value) => switch (value) {
    'admin' => DeletionPersona.admin,
    'client' => DeletionPersona.client,
    'individualProvider' => DeletionPersona.individualProvider,
    'companyProvider' => DeletionPersona.companyProvider,
    'worker' => DeletionPersona.worker,
    'manager' => DeletionPersona.manager,
    _ => DeletionPersona.unknown,
  };
}
