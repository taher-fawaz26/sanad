/// Whether the shared branch wizard is creating a new branch or editing an
/// existing one. Controls the differences between the two flows (initial data,
/// submit action, titles/labels, endpoint, and step-navigation freedom) while
/// the rest of the wizard — UI, validation, draft, components — is shared.
enum BranchFormMode {
  create,
  edit
  ;

  bool get isEdit => this == BranchFormMode.edit;
  bool get isCreate => this == BranchFormMode.create;
}
