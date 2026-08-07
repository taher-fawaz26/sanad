import 'package:document_flow/document_flow.dart';

/// Config for the onboarding sign-up document flow.
///
/// Only the Emirates ID sides are declared "required" here — trade licence
/// is organization-only and its completeness is already gated by
/// `TradeLicencePage`'s own "Next" button, so the shared validator (which
/// can't see the provider-type choice made *after* this config is built)
/// stays a static, always-safe superset check. Extraction runs before
/// submit; there is no prefill (a brand-new provider has no prior documents).
const registrationDocumentFlowConfig = DocumentFlowConfig(
  requiredDocuments: [
    DocumentType.emiratesIdFront,
    DocumentType.emiratesIdBack,
  ],
);
