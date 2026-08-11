import 'package:document_flow/document_flow.dart';

/// Config for the organization legal-documents update flow.
///
/// Every organization has both an Emirates ID and a trade licence, and the
/// flow prefills from whatever is already on file (`enablePrefetch: true`) —
/// unlike onboarding, which always starts empty.
const organizationDocumentFlowConfig = DocumentFlowConfig(
  requiredDocuments: [
    DocumentType.emiratesIdFront,
    DocumentType.emiratesIdBack,
    DocumentType.tradeLicense,
  ],
  enablePrefetch: true,
);
