import 'package:document_flow/document_flow.dart' show DocumentFlowRepository;
import 'package:document_flow/src/domain/repositories/document_flow_repository.dart' show DocumentFlowRepository;

/// `document_flow` has no feature-agnostic dependencies to register: its
/// [DocumentFlowRepository] is always feature-owned, so each feature (e.g.
/// `RegistrationDI`, `OrganizationSettingsDI`) registers its own repository
/// implementation, use cases, and `DocumentFlowBloc` factory bound to it.
///
/// This class exists only so `DocumentFlowModule` has a symmetrical
/// `registerDependencies()` to call, matching every other feature module.
abstract final class DocumentFlowDI {
  DocumentFlowDI._();

  static void init() {}
}
