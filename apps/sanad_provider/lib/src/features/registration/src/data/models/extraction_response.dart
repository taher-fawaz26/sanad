import 'package:document_flow/document_flow.dart';

/// DTO for `POST auth/extract`.
///
/// Parses the backend response into [ExtractedDocuments]. Raw string values
/// are kept under `raw` (keyed by the field name the review page uses to
/// build localized [ExtractedField]s) so this data-layer mapper never needs
/// to know about l10n.
///
/// The backend envelope is flat — no `data` wrapper — and uses verbose key
/// names (`personalLegalData`, `tradeLicenseLegalData`) with camelCase field
/// names (`fullNameEnglish`, `tradeNameArabic`, …). Shorter aliases are kept
/// for forward-compatibility with any future API normalisation.
abstract final class ExtractionResponse {
  ExtractionResponse._();

  static ExtractedDocuments fromJson(
    Map<String, dynamic> json, {
    required bool includeTradeLicence,
  }) {
    final data = _unwrap(json);

    // Backend sends `personalLegalData` for the Emirates ID document.
    final idMap = _map(
      data['personalLegalData'] ??
          data['personal_legal_data'] ??
          data['emiratesId'] ??
          data['emirates_id'],
    );

    // Backend sends `tradeLicenseLegalData` for the trade licence.
    final tlMap = _map(
      data['tradeLicenseLegalData'] ??
          data['trade_license_legal_data'] ??
          data['tradeLicence'] ??
          data['trade_licence'],
    );

    final sections = [
      _parseEmiratesId(idMap),
      if (includeTradeLicence) _parseTradeLicence(tlMap),
    ];

    return ExtractedDocuments(sections: sections);
  }

  static ExtractedDocument _parseEmiratesId(Map<String, dynamic> m) {
    if (m.isEmpty) {
      return const ExtractedDocument(
        type: DocumentType.emiratesIdFront,
        fields: [],
        issue: DocumentIssue.imageUnclear,
      );
    }
    return ExtractedDocument(
      type: DocumentType.emiratesIdFront,
      fields: const [],
      raw: {
        // Backend: fullNameEnglish  |  legacy: fullNameEn / full_name_en / name
        'fullNameEn': _str(
          m,
          ['fullNameEnglish', 'fullNameEn', 'full_name_en', 'name'],
        ),
        // Backend: fullNameArabic  |  legacy: fullNameAr / full_name_ar
        'fullNameAr': _str(m, ['fullNameArabic', 'fullNameAr', 'full_name_ar']),
        'idNumber': _str(
          m,
          ['idNumber', 'id_number', 'emiratesId', 'emirates_id'],
        ),
        'nationality': _str(m, ['nationality']),
        'dateOfBirth': _str(m, ['dateOfBirth', 'date_of_birth', 'dob']),
        'expiryDate': _str(m, ['expiryDate', 'expiry_date', 'expiry']),
        'gender': _str(m, ['gender']),
      },
    );
  }

  static ExtractedDocument _parseTradeLicence(Map<String, dynamic> m) {
    if (m.isEmpty) {
      return const ExtractedDocument(
        type: DocumentType.tradeLicense,
        fields: [],
        issue: DocumentIssue.expired,
      );
    }
    final raw = {
      // Backend: tradeNameEnglish  |  legacy: tradeNameEn / tradeName
      'tradeNameEn': _str(
        m,
        ['tradeNameEnglish', 'tradeNameEn', 'trade_name_en', 'tradeName'],
      ),
      // Backend: tradeNameArabic  |  legacy: tradeNameAr
      'tradeNameAr': _str(
        m,
        ['tradeNameArabic', 'tradeNameAr', 'trade_name_ar'],
      ),
      // Backend: licenseNumber  |  legacy: licenceNo / licenseNo
      'licenceNo': _str(
        m,
        [
          'licenseNumber',
          'licenceNumber',
          'licenceNo',
          'licence_no',
          'licenseNo',
        ],
      ),
      'licenceType': _str(m, ['licenceType', 'licence_type', 'licenseType']),
      'establishmentDate': _str(
        m,
        ['establishmentDate', 'establishment_date'],
      ),
      'issuanceDate': _str(m, ['issuanceDate', 'issuance_date']),
      'legalForm': _str(m, ['legalForm', 'legal_form']),
      // Backend: unifiedRegistrationNumber  |  legacy: unifiedRegNo
      'unifiedRegNo': _str(
        m,
        ['unifiedRegistrationNumber', 'unifiedRegNo', 'unified_reg_no'],
      ),
      // Backend: unifiedLicenseNumber  |  legacy: unifiedLicenceNo
      'unifiedLicenceNo': _str(
        m,
        ['unifiedLicenseNumber', 'unifiedLicenceNo', 'unified_licence_no'],
      ),
    };

    // A non-empty block alone is NOT success. The backend reports, per block,
    // which required fields OCR could not read via `missingFields` — the
    // authoritative signal (the same one the organization-settings extract
    // model consumes). When it's non-empty the extraction is incomplete and
    // the backend will hard-reject the registration at profile completion
    // ("we could not read the trade licence number"), so flag the document for
    // re-upload (generic image-unclear treatment: warning badge + Replace
    // Document + Continue disabled) instead of falsely reporting "Extracted
    // successfully" and letting the user walk into a guaranteed failure with no
    // clear cause (SAN-570). The empty licence number is kept as a defensive
    // fallback in case an older backend omits `missingFields`. The
    // partially-read fields are still shown via [raw].
    final missingFields = _strList(m, ['missingFields', 'missing_fields']);
    final incomplete =
        missingFields.isNotEmpty || (raw['licenceNo'] ?? '').isEmpty;

    return ExtractedDocument(
      type: DocumentType.tradeLicense,
      fields: const [],
      issue: incomplete ? DocumentIssue.imageUnclear : DocumentIssue.none,
      raw: raw,
    );
  }

  /// Builds [ExtractedDocuments] for a **document-domain rejection**: any
  /// `auth/extract` HTTP 400 whose body is a single business message rather
  /// than a field-validation array (e.g. `EXTRACTION_INCOMPLETE`, a
  /// front/back Emirates ID mismatch, an unreadable/unsupported document —
  /// any backend code meaning "the uploaded document itself is the
  /// problem"). This is the single, canonical mapping point for that whole
  /// error class: callers never branch on the specific backend `code`, so a
  /// new backend code needs no client change to render inline.
  ///
  /// The review screen renders the result inline exactly like the
  /// image-unclear/expired outcomes, instead of a full-screen error.
  ///
  /// The affected document is resolved, in priority order, from [fields]
  /// (backend field names, e.g. `license_number`), then [code], then
  /// [message] content — each checked against the same token set so a
  /// mismatch code that names no specific field (e.g. "front and back don't
  /// match") still routes correctly. When nothing resolves, every document in
  /// this extraction is flagged so the user can still act. Unaffected
  /// documents are omitted — the 400 aborts extraction, so no data exists for
  /// them (mirrors the single-section 409 already-registered case).
  ///
  /// Every match always resolves to [DocumentIssue.imageUnclear] — the
  /// generic "this document needs re-uploading" badge/banner/Replace-Document
  /// treatment already used for image-unclear — carrying the backend
  /// [message] as [ExtractedDocument.issueDetail] so the specific reason is
  /// still shown. This is deliberate: introducing a distinct badge per
  /// backend code would mean guessing new visual treatment per code, which
  /// this mapper exists to avoid.
  static ExtractedDocuments fromDomainRejection({
    required List<String> fields,
    required String message,
    required bool includeTradeLicence,
    String? code,
  }) {
    final all = <DocumentType>[
      DocumentType.emiratesIdFront,
      if (includeTradeLicence) DocumentType.tradeLicense,
    ];

    final targets = _resolveAffectedDocuments(
      fields: fields,
      code: code,
      message: message,
      known: all,
    );

    return ExtractedDocuments(
      sections: [
        for (final type in all)
          if (targets.contains(type))
            ExtractedDocument(
              type: type,
              fields: const [],
              issue: DocumentIssue.imageUnclear,
              issueDetail: message.isEmpty ? null : message,
              repair: _repairTargetFor(type, code),
            ),
      ],
    );
  }

  /// Backend codes meaning a whole multi-part document must be replaced
  /// together — never inferred from HTTP status or from `fields` merely
  /// being present, only from an explicit code added here. This is the
  /// single, centralized policy point: a new whole-document backend code is
  /// handled by adding it to this set, nothing else.
  static const _wholeDocumentRepairCodes = {'EXTRACTION_ID_MISMATCH'};

  /// What the user must replace to fix [section]'s issue, or null for the
  /// default single-file replace. Only the Emirates ID is currently a
  /// multi-part document (front + back); a whole-document code against any
  /// other section still resolves to null since there is nothing else to
  /// group it with.
  static DocumentRepairTarget? _repairTargetFor(
    DocumentType section,
    String? code,
  ) {
    if (code == null || !_wholeDocumentRepairCodes.contains(code)) return null;
    if (section != DocumentType.emiratesIdFront) return null;
    return const DocumentRepairTarget(
      parts: [DocumentType.emiratesIdFront, DocumentType.emiratesIdBack],
      scope: DocumentRepairScope.wholeDocument,
    );
  }

  /// Resolves which of [known] documents a rejection concerns. Tries, in
  /// order, the structured [fields] list, the backend [code], then the
  /// [message] text — each against the same token set — so a rejection that
  /// names no specific field (a whole-document mismatch, for instance) still
  /// routes via its code or message. Falls back to every known document when
  /// nothing resolves, so the user can still act.
  static Set<DocumentType> _resolveAffectedDocuments({
    required List<String> fields,
    required String? code,
    required String message,
    required List<DocumentType> known,
  }) {
    final affected = <DocumentType>{};
    for (final field in fields) {
      final type = _documentForTokens(field);
      if (type != null && known.contains(type)) affected.add(type);
    }
    if (affected.isEmpty && code != null) {
      final type = _documentForTokens(code);
      if (type != null && known.contains(type)) affected.add(type);
    }
    if (affected.isEmpty) {
      final type = _documentForTokens(message);
      if (type != null && known.contains(type)) affected.add(type);
    }
    return affected.isNotEmpty ? affected : known.toSet();
  }

  /// Maps a backend field name, error code, or message string to the
  /// document it concerns, or null when it can't be attributed. Token-based
  /// so snake_case (`license_number`), camelCase (`licenseNumber`),
  /// SCREAMING_CASE codes (`TRADE_LICENSE_MISMATCH`), and free-text Arabic or
  /// English messages all resolve the same way.
  static DocumentType? _documentForTokens(String text) {
    final t = text.toLowerCase();
    const tradeTokens = [
      'license',
      'licence',
      'trade',
      'establishment',
      'issuance',
      'unified',
      'legal',
      'رخصة',
      'الرخصة',
    ];
    const emiratesTokens = [
      'emirates',
      'id_number',
      'idnumber',
      'nationality',
      'birth',
      'dob',
      'expiry',
      'gender',
      'full_name',
      'fullname',
      'إماراتية',
      'الإماراتية',
      'الهوية',
      'بطاقة الهوية',
    ];
    if (tradeTokens.any(t.contains)) return DocumentType.tradeLicense;
    if (emiratesTokens.any(t.contains)) return DocumentType.emiratesIdFront;
    return null;
  }

  /// Unwraps a `{ data: {...} }` envelope if present; returns the raw map
  /// otherwise (the extraction endpoint sends a flat response).
  static Map<String, dynamic> _unwrap(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    return json;
  }

  static Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    return const {};
  }

  static String _str(Map<String, dynamic> m, List<String> keys) {
    for (final key in keys) {
      final v = m[key];
      if (v is String && v.isNotEmpty) return v;
    }
    return '';
  }

  /// Reads the first key that holds a list, returning its non-empty string
  /// elements. Used for the backend's `missingFields` array; tolerant of the
  /// key being absent (returns empty) or carrying non-string entries.
  static List<String> _strList(Map<String, dynamic> m, List<String> keys) {
    for (final key in keys) {
      final v = m[key];
      if (v is List) {
        return v
            .whereType<String>()
            .where((e) => e.isNotEmpty)
            .toList(growable: false);
      }
    }
    return const [];
  }
}
