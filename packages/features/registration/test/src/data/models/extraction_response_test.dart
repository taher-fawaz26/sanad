import 'package:flutter_test/flutter_test.dart';
import 'package:registration/src/data/models/extraction_response.dart';
import 'package:registration/src/data/models/extraction_result.dart';

void main() {
  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Minimal Emirates ID block with every canonical field present.
  Map<String, dynamic> _canonicalIdMap({String nameKey = 'fullNameEnglish'}) =>
      {
        nameKey: 'John Doe',
        'fullNameArabic': 'جون دو',
        'idNumber': '784-1990-0000001-1',
        'nationality': 'UAE',
        'dateOfBirth': '01/01/1990',
        'expiryDate': '01/01/2030',
        'gender': 'Male',
      };

  /// Minimal trade licence block with every canonical field present.
  Map<String, dynamic> _canonicalTlMap() => {
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

  ExtractionResult _parse(
    Map<String, dynamic> json, {
    bool includeTradeLicence = false,
  }) =>
      ExtractionResponse.fromJson(json, includeTradeLicence: includeTradeLicence);

  // ── Envelope handling ────────────────────────────────────────────────────────

  group('envelope', () {
    test('uses flat JSON directly when no data wrapper is present', () {
      final json = {'personalLegalData': _canonicalIdMap()};
      final result = _parse(json);
      expect(result.emiratesId.fullNameEn, 'John Doe');
    });

    test('unwraps { data: {...} } envelope before parsing', () {
      final json = {
        'data': {'personalLegalData': _canonicalIdMap()},
      };
      final result = _parse(json);
      expect(result.emiratesId.fullNameEn, 'John Doe');
    });

    test('nested data must be a map — non-map data falls back to outer map', () {
      final json = {
        'data': 'not-a-map',
        'personalLegalData': _canonicalIdMap(),
      };
      final result = _parse(json);
      expect(result.emiratesId.fullNameEn, 'John Doe');
    });
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
        final result = _parse({key: _canonicalIdMap()});
        expect(result.emiratesId.fullNameEn, 'John Doe');
        expect(result.emiratesId.issue, DocumentIssue.none);
      });
    }

    test('missing Emirates ID block returns unclear result', () {
      final result = _parse({});
      expect(result.emiratesId.issue, DocumentIssue.imageUnclear);
      expect(result.emiratesId.fullNameEn, '');
    });

    test('Emirates ID block with non-map value returns unclear result', () {
      final result = _parse({'personalLegalData': 'not-a-map'});
      expect(result.emiratesId.issue, DocumentIssue.imageUnclear);
    });
  });

  // ── Emirates ID field aliases ─────────────────────────────────────────────────

  group('Emirates ID field aliases', () {
    EmiratesIdResult _parseId(Map<String, dynamic> idMap) =>
        _parse({'personalLegalData': idMap}).emiratesId;

    group('fullNameEn', () {
      test('reads "fullNameEnglish" (canonical)', () {
        expect(
          _parseId({'fullNameEnglish': 'Alice', ...{}}).fullNameEn,
          'Alice',
        );
      });
      test('falls back to "fullNameEn"', () {
        expect(_parseId({'fullNameEn': 'Alice'}).fullNameEn, 'Alice');
      });
      test('falls back to "full_name_en"', () {
        expect(_parseId({'full_name_en': 'Alice'}).fullNameEn, 'Alice');
      });
      test('falls back to "name"', () {
        expect(_parseId({'name': 'Alice'}).fullNameEn, 'Alice');
      });
    });

    group('fullNameAr', () {
      test('reads "fullNameArabic" (canonical)', () {
        expect(_parseId({'fullNameArabic': 'علي'}).fullNameAr, 'علي');
      });
      test('falls back to "fullNameAr"', () {
        expect(_parseId({'fullNameAr': 'علي'}).fullNameAr, 'علي');
      });
      test('falls back to "full_name_ar"', () {
        expect(_parseId({'full_name_ar': 'علي'}).fullNameAr, 'علي');
      });
    });

    group('idNumber', () {
      test('reads "idNumber" (canonical)', () {
        expect(
          _parseId({'idNumber': '784-0000-0000001-1'}).idNumber,
          '784-0000-0000001-1',
        );
      });
      test('falls back to "id_number"', () {
        expect(_parseId({'id_number': '784-0000-0000001-1'}).idNumber, '784-0000-0000001-1');
      });
    });

    group('dateOfBirth', () {
      test('reads "dateOfBirth" (canonical)', () {
        expect(_parseId({'dateOfBirth': '01/01/1990'}).dateOfBirth, '01/01/1990');
      });
      test('falls back to "date_of_birth"', () {
        expect(_parseId({'date_of_birth': '01/01/1990'}).dateOfBirth, '01/01/1990');
      });
      test('falls back to "dob"', () {
        expect(_parseId({'dob': '01/01/1990'}).dateOfBirth, '01/01/1990');
      });
    });

    group('expiryDate', () {
      test('reads "expiryDate" (canonical)', () {
        expect(_parseId({'expiryDate': '01/01/2030'}).expiryDate, '01/01/2030');
      });
      test('falls back to "expiry_date"', () {
        expect(_parseId({'expiry_date': '01/01/2030'}).expiryDate, '01/01/2030');
      });
      test('falls back to "expiry"', () {
        expect(_parseId({'expiry': '01/01/2030'}).expiryDate, '01/01/2030');
      });
    });
  });

  // ── _str helper edge cases ───────────────────────────────────────────────────

  group('_str helper', () {
    test('skips empty-string values and uses the next alias', () {
      final result = _parse({
        'personalLegalData': {
          'fullNameEnglish': '', // empty — should be skipped
          'fullNameEn': 'Bob', // next alias used
        },
      });
      expect(result.emiratesId.fullNameEn, 'Bob');
    });

    test('skips non-string values and uses the next alias', () {
      final result = _parse({
        'personalLegalData': {
          'fullNameEnglish': 42, // non-string — skipped
          'fullNameEn': 'Carol',
        },
      });
      expect(result.emiratesId.fullNameEn, 'Carol');
    });

    test('returns empty string when no valid alias resolves', () {
      final result = _parse({
        'personalLegalData': {
          'nationality': 'UAE', // only nationality, no name keys
        },
      });
      expect(result.emiratesId.fullNameEn, '');
      expect(result.emiratesId.nationality, 'UAE');
    });

    test('first non-empty alias wins — higher-priority key is not overridden', () {
      final result = _parse({
        'personalLegalData': {
          'fullNameEnglish': 'Primary', // first alias — wins
          'fullNameEn': 'Secondary',
          'name': 'Tertiary',
        },
      });
      expect(result.emiratesId.fullNameEn, 'Primary');
    });
  });

  // ── Trade licence: includeTradeLicence flag ───────────────────────────────────

  group('includeTradeLicence', () {
    test('false → tradeLicence is null even when data is present', () {
      final json = {
        'personalLegalData': _canonicalIdMap(),
        'tradeLicenseLegalData': _canonicalTlMap(),
      };
      final result = _parse(json, includeTradeLicence: false);
      expect(result.tradeLicence, isNull);
    });

    test('true → tradeLicence is parsed from the block', () {
      final json = {
        'personalLegalData': _canonicalIdMap(),
        'tradeLicenseLegalData': _canonicalTlMap(),
      };
      final result = _parse(json, includeTradeLicence: true);
      expect(result.tradeLicence, isNotNull);
      expect(result.tradeLicence!.tradeNameEn, 'Acme LLC');
    });

    test('true but missing block → TradeLicenceResult.expired()', () {
      final json = {'personalLegalData': _canonicalIdMap()};
      final result = _parse(json, includeTradeLicence: true);
      expect(result.tradeLicence!.issue, DocumentIssue.expiredLicence);
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
          'personalLegalData': _canonicalIdMap(),
          key: _canonicalTlMap(),
        };
        final result = _parse(json, includeTradeLicence: true);
        expect(result.tradeLicence!.tradeNameEn, 'Acme LLC');
        expect(result.tradeLicence!.issue, DocumentIssue.none);
      });
    }
  });

  // ── Trade licence field aliases ───────────────────────────────────────────────

  group('trade licence field aliases', () {
    TradeLicenceResult _parseTl(Map<String, dynamic> tlMap) =>
        _parse(
          {'personalLegalData': _canonicalIdMap(), 'tradeLicenseLegalData': tlMap},
          includeTradeLicence: true,
        ).tradeLicence!;

    group('tradeNameEn', () {
      test('reads "tradeNameEnglish" (canonical)', () {
        expect(_parseTl({'tradeNameEnglish': 'Acme'}).tradeNameEn, 'Acme');
      });
      test('falls back to "tradeNameEn"', () {
        expect(_parseTl({'tradeNameEn': 'Acme'}).tradeNameEn, 'Acme');
      });
      test('falls back to "tradeName"', () {
        expect(_parseTl({'tradeName': 'Acme'}).tradeNameEn, 'Acme');
      });
    });

    group('tradeNameAr', () {
      test('reads "tradeNameArabic" (canonical)', () {
        expect(_parseTl({'tradeNameArabic': 'أكمي'}).tradeNameAr, 'أكمي');
      });
      test('falls back to "tradeNameAr"', () {
        expect(_parseTl({'tradeNameAr': 'أكمي'}).tradeNameAr, 'أكمي');
      });
    });

    group('licenceNo', () {
      test('reads "licenseNumber" (canonical)', () {
        expect(_parseTl({'licenseNumber': 'CN-1'}).licenceNo, 'CN-1');
      });
      test('falls back to "licenceNumber"', () {
        expect(_parseTl({'licenceNumber': 'CN-1'}).licenceNo, 'CN-1');
      });
      test('falls back to "licenceNo"', () {
        expect(_parseTl({'licenceNo': 'CN-1'}).licenceNo, 'CN-1');
      });
      test('falls back to "licence_no"', () {
        expect(_parseTl({'licence_no': 'CN-1'}).licenceNo, 'CN-1');
      });
      test('falls back to "licenseNo"', () {
        expect(_parseTl({'licenseNo': 'CN-1'}).licenceNo, 'CN-1');
      });
    });

    group('unifiedRegNo', () {
      test('reads "unifiedRegistrationNumber" (canonical)', () {
        expect(
          _parseTl({'unifiedRegistrationNumber': 'URN-1'}).unifiedRegNo,
          'URN-1',
        );
      });
      test('falls back to "unifiedRegNo"', () {
        expect(_parseTl({'unifiedRegNo': 'URN-1'}).unifiedRegNo, 'URN-1');
      });
      test('falls back to "unified_reg_no"', () {
        expect(_parseTl({'unified_reg_no': 'URN-1'}).unifiedRegNo, 'URN-1');
      });
    });

    group('unifiedLicenceNo', () {
      test('reads "unifiedLicenseNumber" (canonical)', () {
        expect(
          _parseTl({'unifiedLicenseNumber': 'UL-1'}).unifiedLicenceNo,
          'UL-1',
        );
      });
      test('falls back to "unifiedLicenceNo"', () {
        expect(_parseTl({'unifiedLicenceNo': 'UL-1'}).unifiedLicenceNo, 'UL-1');
      });
      test('falls back to "unified_licence_no"', () {
        expect(
          _parseTl({'unified_licence_no': 'UL-1'}).unifiedLicenceNo,
          'UL-1',
        );
      });
    });
  });

  // ── ExtractionResult derived properties ──────────────────────────────────────

  group('ExtractionResult derived properties', () {
    test('allOk is true when Emirates ID has no issue and no trade licence', () {
      final result = _parse({'personalLegalData': _canonicalIdMap()});
      expect(result.allOk, isTrue);
    });

    test('allOk is true when both documents are clean', () {
      final result = _parse(
        {
          'personalLegalData': _canonicalIdMap(),
          'tradeLicenseLegalData': _canonicalTlMap(),
        },
        includeTradeLicence: true,
      );
      expect(result.allOk, isTrue);
    });

    test('allOk is false when Emirates ID is unclear', () {
      final result = _parse({});
      expect(result.allOk, isFalse);
    });

    test('allOk is false when trade licence is expired', () {
      // tradeLicenseLegalData missing → expired fallback
      final result = _parse(
        {'personalLegalData': _canonicalIdMap()},
        includeTradeLicence: true,
      );
      expect(result.allOk, isFalse);
    });
  });

  // ── Full canonical round-trip ─────────────────────────────────────────────────

  group('full canonical round-trip', () {
    test('individual path — all canonical fields parse correctly', () {
      final json = {'personalLegalData': _canonicalIdMap()};
      final result = _parse(json);
      final id = result.emiratesId;
      expect(id.fullNameEn, 'John Doe');
      expect(id.fullNameAr, 'جون دو');
      expect(id.idNumber, '784-1990-0000001-1');
      expect(id.nationality, 'UAE');
      expect(id.dateOfBirth, '01/01/1990');
      expect(id.expiryDate, '01/01/2030');
      expect(id.gender, 'Male');
      expect(id.issue, DocumentIssue.none);
      expect(result.tradeLicence, isNull);
    });

    test('org path — Emirates ID + trade licence parse correctly', () {
      final json = {
        'personalLegalData': _canonicalIdMap(),
        'tradeLicenseLegalData': _canonicalTlMap(),
      };
      final result = _parse(json, includeTradeLicence: true);
      final tl = result.tradeLicence!;
      expect(tl.tradeNameEn, 'Acme LLC');
      expect(tl.tradeNameAr, 'شركة أكمي');
      expect(tl.licenceNo, 'CN-123');
      expect(tl.licenceType, 'Trade');
      expect(tl.establishmentDate, '01/01/2010');
      expect(tl.issuanceDate, '01/01/2025');
      expect(tl.legalForm, 'LLC');
      expect(tl.unifiedRegNo, 'URN-001');
      expect(tl.unifiedLicenceNo, 'UL-001');
      expect(tl.issue, DocumentIssue.none);
      expect(result.allOk, isTrue);
    });

    test('org path wrapped in data envelope parses correctly', () {
      final json = {
        'data': {
          'personalLegalData': _canonicalIdMap(),
          'tradeLicenseLegalData': _canonicalTlMap(),
        },
      };
      final result = _parse(json, includeTradeLicence: true);
      expect(result.emiratesId.fullNameEn, 'John Doe');
      expect(result.tradeLicence!.tradeNameEn, 'Acme LLC');
      expect(result.allOk, isTrue);
    });
  });
}
