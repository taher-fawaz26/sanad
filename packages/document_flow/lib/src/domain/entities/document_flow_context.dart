import 'package:document_flow/document_flow.dart' show DocumentFlowRepository;
import 'package:document_flow/src/domain/repositories/document_flow_repository.dart'
    show DocumentFlowRepository;

/// Opaque bag of runtime data a feature's [DocumentFlowRepository]
/// implementation needs (e.g. a short-lived onboarding token).
///
/// Keeping this a plain map — instead of a typed field like an auth token —
/// is what lets `document_flow` stay ignorant of `auth`: each feature decides
/// what it needs to seed here and how its repository reads it back.
class DocumentFlowContext {
  const DocumentFlowContext([this.values = const {}]);

  final Map<String, Object?> values;

  T? get<T>(String key) => values[key] as T?;

  DocumentFlowContext copyWith(Map<String, Object?> overrides) =>
      DocumentFlowContext({...values, ...overrides});
}
