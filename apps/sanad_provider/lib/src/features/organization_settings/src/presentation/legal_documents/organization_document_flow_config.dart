import 'package:document_flow/document_flow.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/legal_documents/document_scope.dart';

/// Config for the organization legal-documents update flow, scoped to a
/// single document.
///
/// The flow always prefills from whatever is already on file
/// (`enablePrefetch: true`) — unlike onboarding, which always starts empty —
/// but only [DocumentScope.requiredDocuments] must be present for the flow
/// to be considered complete. This is what keeps an Emirates ID renewal from
/// being blocked on a trade licence the current provider (or persona) may
/// not have, and vice versa.
DocumentFlowConfig organizationDocumentFlowConfigFor(DocumentScope scope) =>
    DocumentFlowConfig(
      requiredDocuments: scope.requiredDocuments,
      enablePrefetch: true,
    );
