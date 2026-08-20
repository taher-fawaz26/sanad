# Registration (Provider Onboarding + Document OCR)

## Purpose

Onboards a provider: captures identity documents (Emirates ID, and for company
providers a Trade Licence), runs OCR extraction, lets the user review the
extracted fields, and submits profile completion.

## Location

`apps/sanad_provider/lib/src/features/registration/`
Document capture/extraction/review is powered by the shared
[`packages/document_flow/`](../../packages/document_flow/) package.

## User Flow

Select account type → capture/upload each document → extraction runs
(`POST auth/extract`) → **Review Information** screen shows extracted fields per
document with a per-card status badge and a **Replace Document** action →
"Continue to Dashboard" submits profile completion. A failed/incomplete
extraction is surfaced inline on the card (not full-screen).

## Architecture

Clean Architecture feature over `document_flow`. A `DocumentFlowBloc` owns the
capture/upload/extract/submit phases; the review page renders each
`ExtractedDocument` via `ExtractedFieldsView`.

## Main Screens

- `presentation/pages/review_information_page.dart` — extracted-fields review +
  Replace/Continue.
- `presentation/pages/trade_licence_page.dart` — trade licence capture.
- `presentation/pages/document_repair_page.dart` — two-sided Emirates ID repair.
- `presentation/widgets/select_capture_method_sheet.dart` — capture source +
  per-document `AssetPickerOptions`.

## Main State Management

`DocumentFlowBloc` (from `document_flow`) with phases
`PhaseIdle/Extracting/Submitting/Success/Failure`. The review page maps submit
phases to `RequestStatus` for `MutationListener`.

## Domain Models

- `ExtractedDocuments` / `ExtractedDocument` (`document_flow`): `type`,
  `issue` (`DocumentIssue`), `issueDetail`, `repair`, `raw` (backend-keyed
  strings), `media`. `allOk` gates "Continue".
- `DocumentType` enum: `emiratesIdFront`, `emiratesIdBack`, `tradeLicense`, …

## API Dependencies

- `POST auth/extract` → `LegalDataExtractionResponseDto`. Blocks:
  `personalLegalData` (Emirates ID) and `tradeLicenseLegalData` (trade licence);
  each carries fields plus `status` and a `missingFields` array. No `data`
  envelope. (Same schema as `POST service-provider/legal-data/extract`.)
- Client DTO: `data/models/extraction_response.dart` (maps blocks → `raw`).

## External Integrations

`asset_picker` (scanner/gallery/files), `media_upload` (document upload).

## Business Rules

- Trade-licence key mappings in the client DTO match the live OpenAPI schema
  (`licenseNumber`, `licenseType`, `establishmentDate`, `legalForm`,
  `unifiedRegistrationNumber`, `unifiedLicenseNumber`, `tradeNameEnglish/Arabic`,
  `issuanceDate`) — verified, not a mapping bug (SAN-570).
- Extraction completeness is driven by the backend's `missingFields` array (with
  a missing-licence-number fallback); a non-empty list flags the document as
  needing re-upload instead of reporting "Extracted successfully" (SAN-570).
- **Replace Document** routes by `ExtractedDocument.type` — never hardcoded to
  the Emirates ID scanner (SAN-570).
- A whole-document `repair` scope (Emirates ID front/back mismatch) opens the
  two-sided repair page instead of a single-file replace.

## Important Constraints

- Only `EXTRACTION_ID_MISMATCH` currently maps to a whole-document repair; other
  incomplete/rejection codes map to the generic image-unclear treatment.

## Known Edge Cases

- HTTP-200 with a partially-populated block + `missingFields` (handled) vs
  HTTP-400 domain rejection (`fromDomainRejection`, inline banner).

## Known Issues

- **Backend/OCR accuracy** (fields absent from the OCR response) is outstanding
  and tracked on SAN-570 for backend follow-up; the client change surfaces
  incompleteness rather than silently accepting it.

## Relevant Source Files

- `presentation/pages/review_information_page.dart`
- `data/models/extraction_response.dart`
- `test/features/registration/src/data/models/extraction_response_test.dart`
- `packages/document_flow/lib/src/domain/entities/extracted_document.dart`
- `packages/document_flow/lib/src/domain/entities/document_type.dart`

## Related Documentation

[`../API_GUIDE.md`](../API_GUIDE.md) ·
[`../../.claude/rules/networking.md`](../../.claude/rules/networking.md) ·
[`otp.md`](otp.md)
