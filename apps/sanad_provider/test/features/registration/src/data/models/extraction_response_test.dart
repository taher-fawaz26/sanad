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

    // Extraction is a preview now (a 200 is not approval): the client no
    // longer synthesizes an issue from an empty/malformed block. Only the
    // response's own explicit signals — `status`, `missingFields`,
    // `idVerification` — determine the issue; a missing/malformed block with
    // none of those set parses as a clean, empty document.
    test('missing Emirates ID block synthesizes no issue', () {
      final result = parse({});
      expect(id0(result).issue, DocumentIssue.none);
    });

    test('Emirates ID block with non-map value synthesizes no issue', () {
      final result = parse({'personalLegalData': 'not-a-map'});
      expect(id0(result).issue, DocumentIssue.none);
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

    test('true but missing block → synthesizes no issue', () {
      final json = {'personalLegalData': canonicalIdMap()};
      final result = parse(json, includeTradeLicence: true);
      expect(tl0(result)!.issue, DocumentIssue.none);
    });
  });

  // ── Trade licence required-field guard ────────────────────────────────────
  //
  // Extraction is a preview: the backend, not the client, decides whether a
  // missing licence number blocks completion (it now reports that via
  // `missingFields`, checked at submit time by `auth/profile`). The client no
  // longer infers "incomplete" from an empty `licenceNo` on its own.

  group('trade licence required-field guard', () {
    test(
      'block present but no licence number, and missingFields not reported '
      '→ clean (none), no client-side inference',
      () {
        // OCR read only the trade name + issuance date; the backend didn't
        // report `missingFields` for this preview. Trusted as-is.
        final json = {
          'personalLegalData': canonicalIdMap(),
          'tradeLicenseLegalData': {
            'tradeNameEnglish': 'Acme LLC',
            'issuanceDate': '01/01/2025',
          },
        };
        final result = parse(json, includeTradeLicence: true);
        expect(tl0(result)!.issue, DocumentIssue.none);
        expect(result.allOk, isTrue);
        // The partially-read fields are still surfaced for the user.
        expect(tl0(result)!.raw['tradeNameEn'], 'Acme LLC');
        expect(tl0(result)!.raw['issuanceDate'], '01/01/2025');
      },
    );

    test('block with a licence number → clean (none) issue', () {
      final json = {
        'personalLegalData': canonicalIdMap(),
        'tradeLicenseLegalData': canonicalTlMap(),
      };
      final result = parse(json, includeTradeLicence: true);
      expect(tl0(result)!.issue, DocumentIssue.none);
      expect(result.allOk, isTrue);
    });

    test(
      'backend missingFields is authoritative: non-empty → imageUnclear even '
      'when the licence number itself was read',
      () {
        // All fields (incl. licenceNo) present, but the backend still reports
        // that some required fields could not be read — trust that signal.
        final tl = {
          ...canonicalTlMap(),
          'missingFields': ['legalForm'],
        };
        final json = {
          'personalLegalData': canonicalIdMap(),
          'tradeLicenseLegalData': tl,
        };
        final result = parse(json, includeTradeLicence: true);
        expect(tl0(result)!.issue, DocumentIssue.imageUnclear);
        expect(result.allOk, isFalse);
        // Carried through to the entity so the review banner can list which
        // fields OCR couldn't read (SAN-575), instead of only a generic
        // "image unclear" message.
        expect(tl0(result)!.missingFields, ['legalForm']);
      },
    );

    test('backend missingFields empty → clean (none) issue', () {
      final tl = {...canonicalTlMap(), 'missingFields': <String>[]};
      final json = {
        'personalLegalData': canonicalIdMap(),
        'tradeLicenseLegalData': tl,
      };
      final result = parse(json, includeTradeLicence: true);
      expect(tl0(result)!.issue, DocumentIssue.none);
      expect(result.allOk, isTrue);
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

    test('allOk is false when Emirates ID reports missingFields', () {
      final result = parse({
        'personalLegalData': {
          ...canonicalIdMap(),
          'missingFields': ['id_number'],
        },
      });
      expect(result.allOk, isFalse);
    });

    test('allOk is false when trade licence status is expired', () {
      final result = parse(
        {
          'personalLegalData': canonicalIdMap(),
          'tradeLicenseLegalData': {...canonicalTlMap(), 'status': 'expired'},
        },
        includeTradeLicence: true,
      );
      expect(result.allOk, isFalse);
    });
  });

  // ── status / missingFields / idVerification (new contract, 200 preview) ──────
  //
  // Extraction is a preview: a `200` always carries whatever the extractor
  // could read, including an expired document, unreadable required fields,
  // or a mismatched Emirates ID front/back. These are the explicit signals
  // the backend now returns — the only signals the client trusts (no more
  // inferring a problem from an empty block, see the groups above).

  group('status', () {
    test('"verified" → DocumentStatus.verified, no issue', () {
      final result = parse({
        'personalLegalData': {...canonicalIdMap(), 'status': 'verified'},
      });
      expect(id0(result).status, DocumentStatus.verified);
      expect(id0(result).issue, DocumentIssue.none);
    });

    test(
      '"expiring_soon" → DocumentStatus.expiringSoon, non-blocking (no '
      'issue, still submittable)',
      () {
        final result = parse({
          'personalLegalData': {
            ...canonicalIdMap(),
            'status': 'expiring_soon',
          },
        });
        expect(id0(result).status, DocumentStatus.expiringSoon);
        expect(id0(result).issue, DocumentIssue.none);
        expect(result.allOk, isTrue);
      },
    );

    test('"expired" → DocumentStatus.expired and DocumentIssue.expired', () {
      final result = parse({
        'personalLegalData': {...canonicalIdMap(), 'status': 'expired'},
      });
      expect(id0(result).status, DocumentStatus.expired);
      expect(id0(result).issue, DocumentIssue.expired);
      expect(result.allOk, isFalse);
    });

    test('missing/unrecognized status defaults to verified', () {
      final result = parse({'personalLegalData': canonicalIdMap()});
      expect(id0(result).status, DocumentStatus.verified);
    });

    test('applies independently to the trade licence section', () {
      final result = parse(
        {
          'personalLegalData': canonicalIdMap(),
          'tradeLicenseLegalData': {
            ...canonicalTlMap(),
            'status': 'expiring_soon',
          },
        },
        includeTradeLicence: true,
      );
      expect(tl0(result)!.status, DocumentStatus.expiringSoon);
      expect(tl0(result)!.issue, DocumentIssue.none);
    });
  });

  group('every extracted field is nullable', () {
    test(
      'an Emirates ID block with only status/missingFields still parses',
      () {
        final result = parse({
          'personalLegalData': {'status': 'verified', 'missingFields': []},
        });
        final doc = id0(result);
        expect(doc.issue, DocumentIssue.none);
        expect(doc.raw['fullNameEn'], '');
        expect(doc.raw['idNumber'], '');
        expect(doc.raw['expiryDate'], '');
      },
    );

    test(
      'a trade licence block with only status/missingFields still parses',
      () {
        final result = parse(
          {
            'personalLegalData': canonicalIdMap(),
            'tradeLicenseLegalData': {
              'status': 'verified',
              'missingFields': [],
            },
          },
          includeTradeLicence: true,
        );
        final doc = tl0(result)!;
        expect(doc.issue, DocumentIssue.none);
        expect(doc.raw['tradeNameEn'], '');
        expect(doc.raw['licenceNo'], '');
      },
    );
  });

  group('idVerification', () {
    test('replaces the old idNumbersMatch field — matched: true', () {
      final result = parse({
        'personalLegalData': {
          ...canonicalIdMap(),
          'idVerification': {'matched': true},
        },
      });
      expect(id0(result).idVerification, const IdVerification(matched: true));
      expect(id0(result).issue, DocumentIssue.none);
    });

    test(
      'matched: false → DocumentIssue.idMismatch and a whole-document repair '
      'target (front + back)',
      () {
        final result = parse({
          'personalLegalData': {
            ...canonicalIdMap(),
            'idVerification': {
              'matched': false,
              'reason': 'front_back_id_mismatch',
            },
          },
        });
        final doc = id0(result);
        expect(doc.idVerification?.matched, isFalse);
        expect(doc.idVerification?.reason, 'front_back_id_mismatch');
        expect(doc.issue, DocumentIssue.idMismatch);
        expect(doc.repair?.scope, DocumentRepairScope.wholeDocument);
        expect(doc.repair?.parts, [
          DocumentType.emiratesIdFront,
          DocumentType.emiratesIdBack,
        ]);
        expect(result.allOk, isFalse);
      },
    );

    test('carries backIdNumber when provided', () {
      final result = parse({
        'personalLegalData': {
          ...canonicalIdMap(),
          'idVerification': {
            'matched': false,
            'backIdNumber': '784-1990-0000002-2',
          },
        },
      });
      expect(id0(result).idVerification?.backIdNumber, '784-1990-0000002-2');
    });

    test('absent idVerification → null, no issue synthesized from it', () {
      final result = parse({'personalLegalData': canonicalIdMap()});
      expect(id0(result).idVerification, isNull);
    });

    test('never appears on the trade licence section (EID-only concept)', () {
      final result = parse(
        {
          'personalLegalData': canonicalIdMap(),
          'tradeLicenseLegalData': canonicalTlMap(),
        },
        includeTradeLicence: true,
      );
      expect(tl0(result)!.idVerification, isNull);
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
        // The raw field(s) the rejection named are carried onto the section
        // so the review banner can render mapped labels instead of the raw
        // backend message text (SAN-575).
        expect(tl.missingFields, ['license_number']);
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
      expect(id.missingFields, ['id_number']);
    });

    test(
      'multiple fields spanning both documents are each attributed to their '
      'own section, not lumped onto one',
      () {
        final result = ExtractionResponse.fromDomainRejection(
          fields: const ['id_number', 'license_number', 'nationality'],
          message: 'msg',
          includeTradeLicence: true,
        );
        expect(id0(result).missingFields, ['id_number', 'nationality']);
        expect(tl0(result)!.missingFields, ['license_number']);
      },
    );

    test(
      'a field that resolves to no document is dropped from missingFields '
      'while other resolvable fields still populate their section',
      () {
        final result = ExtractionResponse.fromDomainRejection(
          fields: const ['id_number', 'some_unrelated_code'],
          message: 'msg',
          includeTradeLicence: true,
        );
        expect(id0(result).missingFields, ['id_number']);
      },
    );

    test(
      'when only one document is known (no trade licence in this '
      'extraction) every field is attributed to it, even if the token '
      "wouldn't otherwise resolve",
      () {
        final result = ExtractionResponse.fromDomainRejection(
          fields: const ['id_number', 'some_unrelated_code'],
          message: 'msg',
          includeTradeLicence: false,
        );
        expect(id0(result).missingFields, [
          'id_number',
          'some_unrelated_code',
        ]);
      },
    );

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
        expect(id.issue, DocumentIssue.idMismatch);
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
      'EXTRACTION_ID_MISMATCH maps to DocumentIssue.idMismatch, not '
      'imageUnclear — the UI shows a semantically correct ID-mismatch '
      'banner instead of the generic "image unclear" message',
      () {
        final result = ExtractionResponse.fromDomainRejection(
          fields: const ['emiratesIdFrontId', 'emiratesIdBackId'],
          code: 'EXTRACTION_ID_MISMATCH',
          message: mismatchMessage,
          includeTradeLicence: false,
        );
        final id = id0(result);
        expect(id.issue, DocumentIssue.idMismatch);
        expect(id.issue, isNot(DocumentIssue.imageUnclear));
      },
    );

    test(
      'an unknown extraction code still falls back to imageUnclear',
      () {
        final result = ExtractionResponse.fromDomainRejection(
          fields: const [],
          code: 'SOME_FUTURE_ERROR',
          message: 'Something happened',
          includeTradeLicence: false,
        );
        expect(id0(result).issue, DocumentIssue.imageUnclear);
      },
    );

    test(
      'null extraction code falls back to imageUnclear',
      () {
        final result = ExtractionResponse.fromDomainRejection(
          fields: const [],
          message: 'Something happened',
          includeTradeLicence: false,
        );
        expect(id0(result).issue, DocumentIssue.imageUnclear);
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
