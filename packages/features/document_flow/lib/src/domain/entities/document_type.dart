/// Strongly typed identifiers for the documents a flow can request.
///
/// Add new members here as new document kinds are onboarded (e.g. passport,
/// vehicle licence) — never branch feature code on a string key.
enum DocumentType {
  emiratesIdFront,
  emiratesIdBack,
  tradeLicense,
  passport,
  vehicleLicense,
  other,
}
