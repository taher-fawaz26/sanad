import 'package:document_flow/document_flow.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_provider/src/features/registration/src/data/models/extraction_response.dart';

void main() {
  // ── Helpers ─────────────────────────────────────────────────────────────────

  Map<String, dynamic> canonicalIdMap({String nameKey = 'fullNameEnglish'}) => {
    nameKey: 'John Doe',
    'fullNameArabic': 'جون دو',
    'idNumber': '784-1990-0000001-1',
    'nationality': 'UAE',
    'dateOfBirth': '01/01/1990',
    'expiryDate': '01/01/2030',
    'gender': 'Male',
  };

  Map<String, dynamic> canonicalTlMap() => {
    'tradeNameEnglish': 'Acme LLC',
    'tradeNameArabic': 'شركة أكمي',
    'licenseNumber': 'CN-123',
    'licenceType': 'Trade',
    'establishmentDate': '01/01/2010',
    'issuanceDate': '01/01/2025',
    'legalForm': 'LLC',
    'unifiedRegistrationNumber': 'URN-001',
    'unifiedLicenseNumber': 'UL-001',
  };

  ExtractedDocuments parse(
    Map<String, dynamic> json, {
    bool includeTradeLicence = false,
  }) => ExtractionResponse.fromJson(
    json,
    includeTradeLicence: includeTradeLicence,
  );

  ExtractedDocument id0(ExtractedDocuments r) =>
      r.sectionOf(DocumentType.emiratesIdFront)!;

  ExtractedDocument? id0Nullable(ExtractedDocuments r) =>
      r.sectionOf(DocumentType.emiratesIdFront);

  ExtractedDocument? tl0(ExtractedDocuments r) =>
      r.sectionOf(DocumentType.tradeLicense);

  // ── Envelope handling ────────────────────────────────────────────────────────

  group('envelope', () {
    test('uses flat JSON directly when no data wrapper is present', () {
      final json = {'personalLegalData': canonicalIdMap()};
      final result = parse(json);
      expect(id0(result).raw['fullNameEn'], 'John Doe');
    });

    test('unwraps { data: {...} } envelope before parsing', () {
      final json = {
        'data': {'personalLegalData': canonicalIdMap()},
      };
      final result = parse(json);
      expect(id0(result).raw['fullNameEn'], 'John Doe');
    });

    test(
      'nested data must be a map — non-map data falls back to outer map',
      () {
        final json = {
          'data': 'not-a-map',
          'personalLegalData': canonicalIdMap(),
        };
        final result = parse(json);
        expect(id0(result).raw['fullNameEn'], 'John Doe');
      },
    );
  });

  // ── Emirates ID block key aliases ────────────────────────────────────────────

  group('Emirates ID block key aliases', () {
    for (final key in const [
      'personalLegalData',
      'personal_legal_data',
      'emiratesId',
      'emirates_id',
    ]) {
      test('parses Emirates ID block under key "$key"', () {
        final result = parse({key: canonicalIdMap()});
        expect(id0(result).raw['fullNameEn'], 'John Doe');
        expect(id0(result).issue, DocumentIssue.none);
      });
    }

    test('missing Emirates ID block returns unclear result', () {
      final result = parse({});
      expect(id0(result).issue, DocumentIssue.imageUnclear);
    });

    test('Emirates ID block with non-map value returns unclear result', () {
      final result = parse({'personalLegalData': 'not-a-map'});
      expect(id0(result).issue, DocumentIssue.imageUnclear);
    });
  });

  // ── Emirates ID field aliases ─────────────────────────────────────────────────

  group('Emirates ID field aliases', () {
    Map<String, String> parseId(Map<String, dynamic> idMap) =>
        id0(parse({'personalLegalData': idMap})).raw;

    group('fullNameEn', () {
      test('reads "fullNameEnglish" (canonical)', () {
        expect(parseId({'fullNameEnglish': 'Alice'})['fullNameEn'], 'Alice');
      });
      test('falls back to "fullNameEn"', () {
        expect(parseId({'fullNameEn': 'Alice'})['fullNameEn'], 'Alice');
      });
      test('falls back to "full_name_en"', () {
        expect(parseId({'full_name_en': 'Alice'})['fullNameEn'], 'Alice');
      });
      test('falls back to "name"', () {
        expect(parseId({'name': 'Alice'})['fullNameEn'], 'Alice');
      });
    });

    group('fullNameAr', () {
      test('reads "fullNameArabic" (canonical)', () {
        expect(parseId({'fullNameArabic': 'علي'})['fullNameAr'], 'علي');
      });
      test('falls back to "fullNameAr"', () {
        expect(parseId({'fullNameAr': 'علي'})['fullNameAr'], 'علي');
      });
      test('falls back to "full_name_ar"', () {
        expect(parseId({'full_name_ar': 'علي'})['fullNameAr'], 'علي');
      });
    });

    group('idNumber', () {
      test('reads "idNumber" (canonical)', () {
        expect(
          parseId({'idNumber': '784-0000-0000001-1'})['idNumber'],
          '784-0000-0000001-1',
        );
      });
      test('falls back to "id_number"', () {
        expect(
          parseId({'id_number': '784-0000-0000001-1'})['idNumber'],
          '784-0000-0000001-1',
        );
      });
    });

    group('dateOfBirth', () {
      test('reads "dateOfBirth" (canonical)', () {
        expect(
          parseId({'dateOfBirth': '01/01/1990'})['dateOfBirth'],
          '01/01/1990',
        );
      });
      test('falls back to "date_of_birth"', () {
        expect(
          parseId({'date_of_birth': '01/01/1990'})['dateOfBirth'],
          '01/01/1990',
        );
      });
      test('falls back to "dob"', () {
        expect(parseId({'dob': '01/01/1990'})['dateOfBirth'], '01/01/1990');
      });
    });

    group('expiryDate', () {
      test('reads "expiryDate" (canonical)', () {
        expect(
          parseId({'expiryDate': '01/01/2030'})['expiryDate'],
          '01/01/2030',
        );
      });
      test('falls back to "expiry_date"', () {
        expect(
          parseId({'expiry_date': '01/01/2030'})['expiryDate'],
          '01/01/2030',
        );
      });
      test('falls back to "expiry"', () {
        expect(parseId({'expiry': '01/01/2030'})['expiryDate'], '01/01/2030');
      });
    });
  });

  // ── _str helper edge cases ───────────────────────────────────────────────────

  group('_str helper', () {
    test('skips empty-string values and uses the next alias', () {
      final result = parse({
        'personalLegalData': {
          'fullNameEnglish': '',
          'fullNameEn': 'Bob',
        },
      });
      expect(id0(result).raw['fullNameEn'], 'Bob');
    });

    test('skips non-string values and uses the next alias', () {
      final result = parse({
        'personalLegalData': {
          'fullNameEnglish': 42,
          'fullNameEn': 'Carol',
        },
      });
      expect(id0(result).raw['fullNameEn'], 'Carol');
    });

    test('returns empty string when no valid alias resolves', () {
      final result = parse({
        'personalLegalData': {'nationality': 'UAE'},
      });
      expect(id0(result).raw['fullNameEn'], '');
      expect(id0(result).raw['nationality'], 'UAE');
    });

    test(
      'first non-empty alias wins — higher-priority key is not overridden',
      () {
        final result = parse({
          'personalLegalData': {
            'fullNameEnglish': 'Primary',
            'fullNameEn': 'Secondary',
            'name': 'Tertiary',
          },
        });
        expect(id0(result).raw['fullNameEn'], 'Primary');
      },
    );
  });

  // ── Trade licence: includeTradeLicence flag ───────────────────────────────────

  group('includeTradeLicence', () {
    test(
      'false → tradeLicence section is absent even when data is present',
      () {
        final json = {
          'personalLegalData': canonicalIdMap(),
          'tradeLicenseLegalData': canonicalTlMap(),
        };
        final result = parse(json);
        expect(tl0(result), isNull);
      },
    );

    test('true → tradeLicence is parsed from the block', () {
      final json = {
        'personalLegalData': canonicalIdMap(),
        'tradeLicenseLegalData': canonicalTlMap(),
      };
      final result = parse(json, includeTradeLicence: true);
      expect(tl0(result), isNotNull);
      expect(tl0(result)!.raw['tradeNameEn'], 'Acme LLC');
    });

    test('true but missing block → expired issue', () {
      final json = {'personalLegalData': canonicalIdMap()};
      final result = parse(json, includeTradeLicence: true);
      expect(tl0(result)!.issue, DocumentIssue.expired);
    });
  });

  // ── Trade licence block key aliases ──────────────────────────────────────────

  group('trade licence block key aliases', () {
    for (final key in const [
      'tradeLicenseLegalData',
      'trade_license_legal_data',
      'tradeLicence',
      'trade_licence',
    ]) {
      test('parses trade licence block under key "$key"', () {
        final json = {
          'personalLegalData': canonicalIdMap(),
          key: canonicalTlMap(),
        };
        final result = parse(json, includeTradeLicence: true);
        expect(tl0(result)!.raw['tradeNameEn'], 'Acme LLC');
        expect(tl0(result)!.issue, DocumentIssue.none);
      });
    }
  });

  // ── Trade licence field aliases ───────────────────────────────────────────────

  group('trade licence field aliases', () {
    Map<String, String> parseTl(Map<String, dynamic> tlMap) => tl0(
      parse(
        {
          'personalLegalData': canonicalIdMap(),
          'tradeLicenseLegalData': tlMap,
        },
        includeTradeLicence: true,
      ),
    )!.raw;

    group('tradeNameEn', () {
      test('reads "tradeNameEnglish" (canonical)', () {
        expect(parseTl({'tradeNameEnglish': 'Acme'})['tradeNameEn'], 'Acme');
      });
      test('falls back to "tradeNameEn"', () {
        expect(parseTl({'tradeNameEn': 'Acme'})['tradeNameEn'], 'Acme');
      });
      test('falls back to "tradeName"', () {
        expect(parseTl({'tradeName': 'Acme'})['tradeNameEn'], 'Acme');
      });
    });

    group('licenceNo', () {
      test('reads "licenseNumber" (canonical)', () {
        expect(parseTl({'licenseNumber': 'CN-1'})['licenceNo'], 'CN-1');
      });
      test('falls back to "licenceNo"', () {
        expect(parseTl({'licenceNo': 'CN-1'})['licenceNo'], 'CN-1');
      });
    });

    group('unifiedRegNo', () {
      test('reads "unifiedRegistrationNumber" (canonical)', () {
        expect(
          parseTl({'unifiedRegistrationNumber': 'URN-1'})['unifiedRegNo'],
          'URN-1',
        );
      });
    });

    group('unifiedLicenceNo', () {
      test('reads "unifiedLicenseNumber" (canonical)', () {
        expect(
          parseTl({'unifiedLicenseNumber': 'UL-1'})['unifiedLicenceNo'],
          'UL-1',
        );
      });
    });
  });

  // ── ExtractedDocuments derived properties ────────────────────────────────────

  group('ExtractedDocuments derived properties', () {
    test(
      'allOk is true when Emirates ID has no issue and no trade licence',
      () {
        final result = parse({'personalLegalData': canonicalIdMap()});
        expect(result.allOk, isTrue);
      },
    );

    test('allOk is true when both documents are clean', () {
      final result = parse(
        {
          'personalLegalData': canonicalIdMap(),
          'tradeLicenseLegalData': canonicalTlMap(),
        },
        includeTradeLicence: true,
      );
      expect(result.allOk, isTrue);
    });

    test('allOk is false when Emirates ID is unclear', () {
      final result = parse({});
      expect(result.allOk, isFalse);
    });

    test('allOk is false when trade licence is expired', () {
      final result = parse(
        {'personalLegalData': canonicalIdMap()},
        includeTradeLicence: true,
      );
      expect(result.allOk, isFalse);
    });
  });

  // ── Document-domain rejections → inline flagged sections ─────────────────────
  //
  // This is the single, canonical mapping point for the WHOLE class of
  // "the uploaded document is the problem" backend rejections — not just
  // EXTRACTION_INCOMPLETE. Callers never branch on a specific `code`, so a
  // brand-new backend code (a future OCR/validation failure the client has
  // never seen) still routes correctly with zero client changes, as covered
  // below by the "unrecognized code" cases.

  group('ExtractionResponse.fromDomainRejection', () {
    const incompleteMessage =
        'لم نتمكن من قراءة الحقول المطلوبة التالية في الرخصة التجارية: '
        'license_number. يرجى رفع صورة أوضح ثم إعادة الاستخراج.';

    const mismatchMessage =
        'الوجه الأمامي والخلفي للهوية الإماراتية لا يتطابقان. '
        'يرجى رفع وجهي البطاقة نفسها ثم إعادة الاستخراج.';

    test(
      'EXTRACTION_INCOMPLETE + license_number field flags ONLY the trade '
      'licence card with the backend message, as image-unclear (existing '
      'recovery UX) — unchanged by the generalization',
      () {
        final result = ExtractionResponse.fromDomainRejection(
          fields: const ['license_number'],
          code: 'EXTRACTION_INCOMPLETE',
          message: incompleteMessage,
          includeTradeLicence: true,
        );
        // Only the affected document is present (unaffected omitted).
        expect(id0Nullable(result), isNull);
        final tl = tl0(result)!;
        expect(tl.issue, DocumentIssue.imageUnclear);
        expect(tl.issueDetail, incompleteMessage);
        expect(tl.repair, isNull); // single-part — default replace unchanged
        expect(result.allOk, isFalse);
      },
    );

    test('an Emirates ID field flags only the Emirates ID card', () {
      final result = ExtractionResponse.fromDomainRejection(
        fields: const ['id_number'],
        message: 'msg',
        includeTradeLicence: true,
      );
      expect(tl0(result), isNull);
      final id = id0(result);
      expect(id.issue, DocumentIssue.imageUnclear);
      expect(id.issueDetail, 'msg');
    });

    test('camelCase field names resolve too (licenseNumber → trade)', () {
      final result = ExtractionResponse.fromDomainRejection(
        fields: const ['licenseNumber'],
        message: 'msg',
        includeTradeLicence: true,
      );
      expect(id0Nullable(result), isNull);
      expect(tl0(result)!.issue, DocumentIssue.imageUnclear);
    });

    test(
      'a front/back Emirates ID mismatch — an UNRECOGNIZED code with no '
      '`fields` — still routes to the Emirates ID card via the message '
      'text, and is NOT sent to the full-screen error page. Because this '
      'exact code is unrecognized, repair scope defaults to null '
      '(single-file replace) — repair scope is a distinct, more '
      'conservative decision than routing (see the confirmed-code test '
      'below for the whole-document case)',
      () {
        final result = ExtractionResponse.fromDomainRejection(
          fields: const [],
          code: 'EMIRATES_ID_SIDE_MISMATCH', // any code the client has
          // never seen before — the mapper must not need to recognize it.
          message: mismatchMessage,
          includeTradeLicence: true,
        );
        expect(tl0(result), isNull);
        final id = id0(result);
        expect(id.issue, DocumentIssue.imageUnclear);
        expect(id.issueDetail, mismatchMessage);
        expect(id.repair, isNull);
      },
    );

    test(
      'EXTRACTION_ID_MISMATCH (the confirmed live backend code) attaches a '
      'wholeDocument repair target covering both Emirates ID sides — '
      'Replace Document must open the two-sided repair flow, not a '
      'single-file picker',
      () {
        final result = ExtractionResponse.fromDomainRejection(
          fields: const ['emiratesIdFrontId', 'emiratesIdBackId'],
          code: 'EXTRACTION_ID_MISMATCH',
          message: mismatchMessage,
          includeTradeLicence: true,
        );
        expect(tl0(result), isNull);
        final id = id0(result);
        expect(id.issue, DocumentIssue.imageUnclear);
        expect(id.issueDetail, mismatchMessage);
        expect(
          id.repair,
          const DocumentRepairTarget(
            parts: [DocumentType.emiratesIdFront, DocumentType.emiratesIdBack],
            scope: DocumentRepairScope.wholeDocument,
          ),
        );
      },
    );

    test(
      'EXTRACTION_ID_MISMATCH against the trade licence section (should '
      'never happen in practice) still resolves repair to null — only the '
      'Emirates ID section is a recognized multi-part document',
      () {
        // license_number routes this to the trade licence card even though
        // the code is the Emirates ID mismatch code, to exercise the guard.
        final result = ExtractionResponse.fromDomainRejection(
          fields: const ['license_number'],
          code: 'EXTRACTION_ID_MISMATCH',
          message: 'msg',
          includeTradeLicence: true,
        );
        expect(id0Nullable(result), isNull);
        expect(tl0(result)!.repair, isNull);
      },
    );

    test(
      'an unrecognized code alone (no fields, generic message) resolves the '
      'document via the code text',
      () {
        final result = ExtractionResponse.fromDomainRejection(
          fields: const [],
          code: 'TRADE_LICENSE_UNREADABLE',
          message: 'Please try again.',
          includeTradeLicence: true,
        );
        expect(id0Nullable(result), isNull);
        expect(tl0(result)!.issue, DocumentIssue.imageUnclear);
      },
    );

    test(
      'unmappable fields/code/message fall back to flagging every document '
      'in the extraction',
      () {
        final result = ExtractionResponse.fromDomainRejection(
          fields: const [],
          code: 'SOME_UNKNOWN_ERROR',
          message: 'Please try again.',
          includeTradeLicence: true,
        );
        expect(id0(result).issue, DocumentIssue.imageUnclear);
        expect(tl0(result)!.issue, DocumentIssue.imageUnclear);
      },
    );

    test('a trade-license field never appears when licence is excluded', () {
      final result = ExtractionResponse.fromDomainRejection(
        fields: const ['license_number'],
        message: 'msg',
        includeTradeLicence: false,
      );
      // No trade licence in this extraction → falls back to the only doc.
      expect(tl0(result), isNull);
      expect(id0(result).issue, DocumentIssue.imageUnclear);
    });

    test('empty message leaves issueDetail null (static banner copy used)', () {
      final result = ExtractionResponse.fromDomainRejection(
        fields: const ['license_number'],
        message: '',
        includeTradeLicence: true,
      );
      expect(tl0(result)!.issueDetail, isNull);
    });
  });

  // ── Full canonical round-trip ─────────────────────────────────────────────────

  group('full canonical round-trip', () {
    test('individual path — all canonical fields parse correctly', () {
      final json = {'personalLegalData': canonicalIdMap()};
      final result = parse(json);
      final id = id0(result).raw;
      expect(id['fullNameEn'], 'John Doe');
      expect(id['fullNameAr'], 'جون دو');
      expect(id['idNumber'], '784-1990-0000001-1');
      expect(id['nationality'], 'UAE');
      expect(id['dateOfBirth'], '01/01/1990');
      expect(id['expiryDate'], '01/01/2030');
      expect(id['gender'], 'Male');
      expect(id0(result).issue, DocumentIssue.none);
      expect(tl0(result), isNull);
    });

    test('org path — Emirates ID + trade licence parse correctly', () {
      final json = {
        'personalLegalData': canonicalIdMap(),
        'tradeLicenseLegalData': canonicalTlMap(),
      };
      final result = parse(json, includeTradeLicence: true);
      final tl = tl0(result)!.raw;
      expect(tl['tradeNameEn'], 'Acme LLC');
      expect(tl['tradeNameAr'], 'شركة أكمي');
      expect(tl['licenceNo'], 'CN-123');
      expect(tl['licenceType'], 'Trade');
      expect(tl['establishmentDate'], '01/01/2010');
      expect(tl['issuanceDate'], '01/01/2025');
      expect(tl['legalForm'], 'LLC');
      expect(tl['unifiedRegNo'], 'URN-001');
      expect(tl['unifiedLicenceNo'], 'UL-001');
      expect(tl0(result)!.issue, DocumentIssue.none);
      expect(result.allOk, isTrue);
    });

    test('org path wrapped in data envelope parses correctly', () {
      final json = {
        'data': {
          'personalLegalData': canonicalIdMap(),
          'tradeLicenseLegalData': canonicalTlMap(),
        },
      };
      final result = parse(json, includeTradeLicence: true);
      expect(id0(result).raw['fullNameEn'], 'John Doe');
      expect(tl0(result)!.raw['tradeNameEn'], 'Acme LLC');
      expect(result.allOk, isTrue);
    });
  });
}
