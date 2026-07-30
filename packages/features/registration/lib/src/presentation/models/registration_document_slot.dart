/// Identifies a registration document upload slot.
///
/// Used as the cancel/upload key so Emirates ID, trade licence, and future
/// documents share one upload pipeline.
enum RegistrationDocumentSlot {
  emiratesIdFront,
  emiratesIdBack,
  tradeLicence,
}
