import 'package:document_flow/document_flow.dart';

/// DTO for `POST auth/extract`.
///
/// Extraction is a preview: a `200` always carries whatever the extractor
/// could read, even an expired document, unreadable required fields, or a
/// mismatched Emirates ID front/back — the backend refuses only later, at
/// `auth/profile`. [fromJson] trusts the response's own `status`,
/// `missingFields`, and `idVerification` signals rather than inferring a
/// problem from an empty block.
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
    final status = DocumentStatus.fromWire(_rawStatus(m));
    final missingFields = _strList(m, ['missingFields', 'missing_fields']);
    final idVerification = _idVerification(m['idVerification']);
    return ExtractedDocument(
      type: DocumentType.emiratesIdFront,
      fields: const [],
      status: status,
      missingFields: missingFields,
      idVerification: idVerification,
      issue: deriveDocumentIssue(
        status: status,
        missingFields: missingFields,
        idVerification: idVerification,
      ),
      repair: idVerification != null && !idVerification.matched
          ? emiratesIdMismatchRepairTarget
          : null,
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
    final status = DocumentStatus.fromWire(_rawStatus(m));
    final missingFields = _strList(m, ['missingFields', 'missing_fields']);
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

    return ExtractedDocument(
      type: DocumentType.tradeLicense,
      fields: const [],
      status: status,
      raw: raw,
      missingFields: missingFields,
      issue: deriveDocumentIssue(status: status, missingFields: missingFields),
    );
  }

  /// Parses the Emirates ID front/back comparison object, or null when the
  /// backend omitted it (e.g. no trade-licence-style "not applicable" case
  /// exists for Emirates ID, but a malformed/older response might still lack
  /// the key).
  static IdVerification? _idVerification(dynamic value) {
    final m = _map(value);
    if (m.isEmpty) return null;
    final matched = m['matched'];
    if (matched is! bool) return null;
    final reason = _str(m, ['reason']);
    final backIdNumber = _str(m, ['backIdNumber']);
    return IdVerification(
      matched: matched,
      reason: reason.isEmpty ? null : reason,
      backIdNumber: backIdNumber.isEmpty ? null : backIdNumber,
    );
  }

  /// Builds [ExtractedDocuments] for a **document-domain rejection** at
  /// `auth/profile` (submit): a 400 whose `code` is `EXTRACTION_INCOMPLETE`,
  /// `EXTRACTION_EXPIRED`, or `EXTRACTION_ID_MISMATCH` — the backend judges
  /// the documents at submit time now, not at extract, so this is invoked
  /// from `ReviewInformationPage._onSubmitFailure` rather than from the
  /// extract call site. This remains the single, canonical mapping point for
  /// that error class: callers never branch on the specific backend `code`
  /// beyond routing here, so a new backend code needs no client change to
  /// render inline.
  ///
  /// The review screen renders the result inline exactly like the
  /// image-unclear/expired outcomes, instead of a full-screen error.
  ///
  /// The affected document is resolved, in priority order, from [fields]
  /// (backend field names, e.g. `license_number`), then [code], then
  /// [message] content — each checked against the same token set so a
  /// mismatch code that names no specific field (e.g. "front and back don't
  /// match") still routes correctly. When nothing resolves, every document in
  /// this submission is flagged so the user can still act. Unaffected
  /// documents are omitted — the rejection aborts submit, so no fresh data
  /// exists for them (mirrors the single-section 409 already-registered
  /// case).
  ///
  /// Maps to a semantically correct [DocumentIssue] based on the backend
  /// [code]: `EXTRACTION_ID_MISMATCH` → [DocumentIssue.idMismatch] (the
  /// front and back don't belong to the same card); everything else falls
  /// back to [DocumentIssue.imageUnclear] (the generic "re-upload" banner).
  /// The backend [message] is still carried as [ExtractedDocument.issueDetail]
  /// so the specific reason is shown when no structured field list applies.
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

    final issue = _issueForCode(code);

    return ExtractedDocuments(
      sections: [
        for (final type in all)
          if (targets.contains(type))
            ExtractedDocument(
              type: type,
              fields: const [],
              issue: issue,
              issueDetail: message.isEmpty ? null : message,
              repair: _repairTargetFor(type, code),
              missingFields: _fieldsFor(type, fields: fields, known: all),
            ),
      ],
    );
  }

  static DocumentIssue _issueForCode(String? code) => switch (code) {
    'EXTRACTION_ID_MISMATCH' => DocumentIssue.idMismatch,
    _ => DocumentIssue.imageUnclear,
  };

  /// Which of [fields] belong to [type], for the missing-fields banner.
  ///
  /// Uses the same [_documentForTokens] attribution as
  /// [_resolveAffectedDocuments]. When [known] has only one document (no
  /// trade licence in this extraction, or every field is ambiguous), every
  /// field is attributed to it rather than dropped — mirrors the "fall back
  /// to all known documents" behavior [_resolveAffectedDocuments] uses.
  static List<String> _fieldsFor(
    DocumentType type, {
    required List<String> fields,
    required List<DocumentType> known,
  }) {
    if (known.length == 1) return fields;
    final attributed = fields
        .where((f) => _documentForTokens(f) == type)
        .toList(growable: false);
    if (attributed.isNotEmpty) return attributed;
    // No field individually resolves to this document (e.g. a whole-document
    // mismatch code with no per-field breakdown) — nothing to list for it.
    final anyResolved = fields.any((f) => _documentForTokens(f) != null);
    return anyResolved ? const [] : fields;
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
    return emiratesIdMismatchRepairTarget;
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

  static String? _rawStatus(Map<String, dynamic> m) {
    final v = m['status'];
    return v is String ? v : null;
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
