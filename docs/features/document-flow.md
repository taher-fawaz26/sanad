# Document Flow (Shared Pipeline)

## Purpose

Reusable document upload → OCR extract → review → submit workflow: one
`DocumentFlowBloc`, one upload/extract/submit pipeline, one set of shared
widgets. Each consuming feature supplies its own `DocumentFlowRepository`
implementation, endpoint/request/response mapping, a `DocumentFlowConfig`, and
its own screens.

## Location

[`packages/document_flow/`](../../packages/document_flow/) — shared package,
tier 4 in `dep_rules.yaml`. Barrel: `packages/document_flow/lib/document_flow.dart`.

Consumers (verified): `apps/sanad_provider/lib/src/features/registration/`
(see [registration.md](registration.md)) and
`apps/sanad_provider/lib/src/features/organization_settings/` (legal-documents
sub-flow, see [organization-settings.md](organization-settings.md)).

## Architecture

Clean Architecture: `src/domain/entities/` (`DocumentFlowConfig`,
`DocumentFlowContext`, `DocumentMedia`, `DocumentRepairTarget`, `DocumentType`,
`DocumentValidation`, `ExtractedDocument`, `ExtractedField`),
`src/domain/failures/` (`DocumentFlowFailure` hierarchy),
`src/domain/repositories/` (`DocumentFlowRepository` contract, implemented per
consumer), `src/domain/usecases/` (`ExtractDocumentsUseCase`,
`FetchDocumentsUseCase`, `SubmitDocumentsUseCase`, `UploadMediaUseCase`),
`src/presentation/bloc/` (`DocumentFlowBloc`), `src/presentation/controller/`,
`src/presentation/widgets/` (`DocumentFlowCapture`, `DocumentPreview`,
`DocumentUploadCard`, `ExtractedFieldsView`), `src/di/`, `src/module/`
(`DocumentFlowModule`).

## Main Flow

Pick/capture a document (`DocumentPicked`) → `DocumentUploadRequested` uploads
it → `ExtractionRequested` runs OCR via the consumer's
`DocumentFlowRepository` → extracted fields render per document
(`ExtractedFieldsView`) with a per-document `DocumentIssue` status → user edits
if needed (`EditingStarted`) → `SubmitRequested` submits. `RetryRequested` and
`FlowReset` support recovery; `DocumentRemoved`/`DocumentUploadCancelled`
support removing an in-progress document.

## Main State Management

`presentation/bloc/document_flow_bloc.dart` — `DocumentFlowBloc`.

- Events (`document_flow_event.dart`): `DocumentFlowStarted`, `DocumentPicked`,
  `DocumentUploadRequested`, `DocumentUploadCancelled`, `DocumentRemoved`,
  `ExtractionRequested`, `EditingStarted`, `SubmitRequested`, `FlowReset`,
  `RetryRequested`.
- Phases (`document_flow_state.dart`, a `DocumentFlowPhase` hierarchy):
  `PhaseIdle`, `PhaseExtracting`, `PhaseExtracted`, `PhaseEditing`,
  `PhaseSubmitting`, `PhaseSuccess`, `PhaseFailure`.

## Domain Models

- `ExtractedDocument` — `type` (`DocumentType`), `issue` (`DocumentIssue`:
  `none`/`imageUnclear`/`alreadyRegistered`/`expired`), `issueDetail`,
  `repair` (`DocumentRepairTarget?`), `fields`, `raw` (backend-keyed string
  map), `media`. `ok` ⇔ `issue == DocumentIssue.none`.
- `ExtractedDocuments` — `sections: List<ExtractedDocument>`; `allOk` gates
  submit; `sectionOf(type)` looks up one document's section.
- `DocumentFlowFailure` (sealed, `Equatable`) — `UploadFailure`,
  `ExtractionFailure` (carries `ExtractionFailureKind`
  `missingContext`/`network`/`server`/`domain`, optional backend `code`,
  `fields`, `requestId`), `SubmitFailure`. Each carries a `messageKey`.

## Important APIs

Endpoint/request shape is owned by each consumer's own
`DocumentFlowRepository` implementation (e.g. registration's `POST
auth/extract`, organization settings' `POST service-provider/legal-data/extract`
— see [registration.md](registration.md)); `document_flow` itself defines only
the contract and shared use cases, not a fixed endpoint.

## Important Integrations

- `media_upload` — underlying multipart upload pipeline for
  `UploadMediaUseCase`.
- `asset_picker` — capture/pick source (scanner/gallery/files) feeding
  `DocumentPicked`.
- `shared_ui` — hosts `ExtractedFieldsView`'s presentation primitives.

## Business Rules

- `ExtractionFailureKind.domain` means the backend intentionally rejected the
  request with a user-facing message (business rule/validation/conflict) —
  show that message, not a generic connectivity error. `network`/`server` are
  transport/unclassified failures.
- A `DocumentFlowFailure` always carries a `messageKey`, resolved for display
  the same way as any other `Failure` (see
  [networking.md](../../.claude/rules/networking.md)).

## Important Constraints

- `DocumentFlowRepository` is a contract only — there is no default/generic
  implementation; every consumer must supply its own.

## Known Edge Cases / Unknowns

- The prior draft of this doc set asserted `DocumentFlowBloc` specifically
  hangs when driven live inside `testWidgets`. That claim had **no supporting
  evidence** in the repo (no comment, test, or issue found) and has been
  removed — see the general widget-testing guidance in
  [testing.md](../../.claude/rules/testing.md) instead. If this bloc has a
  concrete, reproducible test-hang issue, document it here with the specific
  cause (e.g. a repeating timer/stream) when confirmed.

## Relevant Source Files

- `packages/document_flow/lib/src/presentation/bloc/document_flow_bloc.dart`
- `packages/document_flow/lib/src/presentation/bloc/document_flow_event.dart`
- `packages/document_flow/lib/src/presentation/bloc/document_flow_state.dart`
- `packages/document_flow/lib/src/domain/entities/extracted_document.dart`
- `packages/document_flow/lib/src/domain/failures/document_flow_failure.dart`
- `packages/document_flow/lib/src/domain/repositories/document_flow_repository.dart`

## Related Documentation

[`registration.md`](registration.md) ·
[`organization-settings.md`](organization-settings.md) ·
[`../../.claude/rules/networking.md`](../../.claude/rules/networking.md) ·
[`../../.claude/rules/testing.md`](../../.claude/rules/testing.md)
