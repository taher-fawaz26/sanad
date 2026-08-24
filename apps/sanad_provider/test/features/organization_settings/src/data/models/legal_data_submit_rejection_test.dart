import 'package:document_flow/document_flow.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/models/legal_data_submit_rejection.dart';

void main() {
  group('LegalDataSubmitRejection.flag', () {
    test('EXTRACTION_INCOMPLETE maps to imageUnclear with missingFields', () {
      final result = LegalDataSubmitRejection.flag(
        type: DocumentType.emiratesIdFront,
        previous: null,
        fields: const ['id_number'],
        message: 'Required identifier could not be read.',
        code: 'EXTRACTION_INCOMPLETE',
      );

      final section = result.sectionOf(DocumentType.emiratesIdFront)!;
      expect(section.issue, DocumentIssue.imageUnclear);
      expect(section.missingFields, ['id_number']);
      expect(section.issueDetail, 'Required identifier could not be read.');
      expect(section.repair, isNull);
    });

    test(
      'EXTRACTION_EXPIRED maps to imageUnclear (generic, not "expired")',
      () {
        // The replacement document is itself expired — a request-time
        // rejection of the NEW upload, distinct from `DocumentIssue.expired`
        // (which reflects a stored/extracted document's own `status`). The
        // generic "re-upload" treatment is correct here since there is no
        // fresher extraction to show a real expiry date from.
        final result = LegalDataSubmitRejection.flag(
          type: DocumentType.tradeLicense,
          previous: null,
          fields: const [],
          message: 'The replacement document has itself expired.',
          code: 'EXTRACTION_EXPIRED',
        );

        final section = result.sectionOf(DocumentType.tradeLicense)!;
        expect(section.issue, DocumentIssue.imageUnclear);
      },
    );

    test(
      'EXTRACTION_ID_MISMATCH on the Emirates ID maps to idMismatch with a '
      'whole-document repair target',
      () {
        final result = LegalDataSubmitRejection.flag(
          type: DocumentType.emiratesIdFront,
          previous: null,
          fields: const [],
          message: 'The two sides disagree.',
          code: 'EXTRACTION_ID_MISMATCH',
        );

        final section = result.sectionOf(DocumentType.emiratesIdFront)!;
        expect(section.issue, DocumentIssue.idMismatch);
        expect(section.repair?.scope, DocumentRepairScope.wholeDocument);
        expect(section.repair?.parts, [
          DocumentType.emiratesIdFront,
          DocumentType.emiratesIdBack,
        ]);
      },
    );

    test(
      'EXTRACTION_ID_MISMATCH on the trade licence resolves repair to null '
      '— only the Emirates ID is a multi-part document',
      () {
        final result = LegalDataSubmitRejection.flag(
          type: DocumentType.tradeLicense,
          previous: null,
          fields: const [],
          message: 'unexpected',
          code: 'EXTRACTION_ID_MISMATCH',
        );

        final section = result.sectionOf(DocumentType.tradeLicense)!;
        expect(section.repair, isNull);
      },
    );

    test('an empty message leaves issueDetail null (static copy used)', () {
      final result = LegalDataSubmitRejection.flag(
        type: DocumentType.emiratesIdFront,
        previous: null,
        fields: const [],
        message: '',
        code: 'EXTRACTION_INCOMPLETE',
      );

      expect(
        result.sectionOf(DocumentType.emiratesIdFront)!.issueDetail,
        isNull,
      );
    });

    test(
      "preserves the previous section's fields/raw/media/status so already "
      'shown values keep rendering, overriding only the rejection outcome',
      () {
        const previous = ExtractedDocument(
          type: DocumentType.emiratesIdFront,
          fields: [],
          raw: {'fullNameEn': 'John Doe'},
          status: DocumentStatus.verified,
          idVerification: IdVerification(matched: true),
        );

        final result = LegalDataSubmitRejection.flag(
          type: DocumentType.emiratesIdFront,
          previous: previous,
          fields: const ['id_number'],
          message: 'Could not read the identifier.',
          code: 'EXTRACTION_INCOMPLETE',
        );

        final section = result.sectionOf(DocumentType.emiratesIdFront)!;
        expect(section.raw, {'fullNameEn': 'John Doe'});
        expect(section.status, DocumentStatus.verified);
        expect(section.idVerification, const IdVerification(matched: true));
        expect(section.issue, DocumentIssue.imageUnclear);
      },
    );

    test('a null previous section still produces a usable flagged section', () {
      final result = LegalDataSubmitRejection.flag(
        type: DocumentType.tradeLicense,
        previous: null,
        fields: const ['license_number'],
        message: 'Could not read the licence number.',
        code: 'EXTRACTION_INCOMPLETE',
      );

      final section = result.sectionOf(DocumentType.tradeLicense)!;
      expect(section.raw, isEmpty);
      expect(section.fields, isEmpty);
      expect(section.missingFields, ['license_number']);
    });

    test('an unrecognized code falls back to imageUnclear', () {
      final result = LegalDataSubmitRejection.flag(
        type: DocumentType.emiratesIdFront,
        previous: null,
        fields: const [],
        message: 'unexpected',
        code: 'SOME_FUTURE_CODE',
      );

      expect(
        result.sectionOf(DocumentType.emiratesIdFront)!.issue,
        DocumentIssue.imageUnclear,
      );
    });
  });
}
