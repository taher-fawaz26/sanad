import 'package:registration/src/data/models/extraction_result.dart';

/// DTO for `POST auth/extract`.
///
/// Parses the backend response into an [ExtractionResult]. All string fields
/// fall back to empty string so the UI can detect missing data without null
/// checks.
///
/// The backend envelope is flat — no `data` wrapper — and uses verbose key
/// names (`personalLegalData`, `tradeLicenseLegalData`) with camelCase field
/// names (`fullNameEnglish`, `tradeNameArabic`, …). Shorter aliases are kept
/// for forward-compatibility with any future API normalisation.
abstract final class ExtractionResponse {
  ExtractionResponse._();

  static ExtractionResult fromJson(
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

    final emiratesId = _parseEmiratesId(idMap);
    final tradeLicence =
        includeTradeLicence ? _parseTradeLicence(tlMap) : null;

    return ExtractionResult(
      emiratesId: emiratesId,
      tradeLicence: tradeLicence,
    );
  }

  static EmiratesIdResult _parseEmiratesId(Map<String, dynamic> m) {
    if (m.isEmpty) return const EmiratesIdResult.unclear();
    return EmiratesIdResult(
      // Backend: fullNameEnglish  |  legacy: fullNameEn / full_name_en / name
      fullNameEn: _str(
        m,
        ['fullNameEnglish', 'fullNameEn', 'full_name_en', 'name'],
      ),
      // Backend: fullNameArabic  |  legacy: fullNameAr / full_name_ar
      fullNameAr: _str(m, ['fullNameArabic', 'fullNameAr', 'full_name_ar']),
      idNumber: _str(
        m,
        ['idNumber', 'id_number', 'emiratesId', 'emirates_id'],
      ),
      nationality: _str(m, ['nationality']),
      dateOfBirth: _str(m, ['dateOfBirth', 'date_of_birth', 'dob']),
      expiryDate: _str(m, ['expiryDate', 'expiry_date', 'expiry']),
      gender: _str(m, ['gender']),
    );
  }

  static TradeLicenceResult _parseTradeLicence(Map<String, dynamic> m) {
    if (m.isEmpty) return const TradeLicenceResult.expired();
    return TradeLicenceResult(
      // Backend: tradeNameEnglish  |  legacy: tradeNameEn / tradeName
      tradeNameEn: _str(
        m,
        ['tradeNameEnglish', 'tradeNameEn', 'trade_name_en', 'tradeName'],
      ),
      // Backend: tradeNameArabic  |  legacy: tradeNameAr
      tradeNameAr: _str(m, ['tradeNameArabic', 'tradeNameAr', 'trade_name_ar']),
      // Backend: licenseNumber  |  legacy: licenceNo / licenseNo
      licenceNo: _str(
        m,
        ['licenseNumber', 'licenceNumber', 'licenceNo', 'licence_no',
         'licenseNo'],
      ),
      licenceType: _str(m, ['licenceType', 'licence_type', 'licenseType']),
      establishmentDate: _str(m, ['establishmentDate', 'establishment_date']),
      issuanceDate: _str(m, ['issuanceDate', 'issuance_date']),
      legalForm: _str(m, ['legalForm', 'legal_form']),
      // Backend: unifiedRegistrationNumber  |  legacy: unifiedRegNo
      unifiedRegNo: _str(
        m,
        ['unifiedRegistrationNumber', 'unifiedRegNo', 'unified_reg_no'],
      ),
      // Backend: unifiedLicenseNumber  |  legacy: unifiedLicenceNo
      unifiedLicenceNo: _str(
        m,
        ['unifiedLicenseNumber', 'unifiedLicenceNo', 'unified_licence_no'],
      ),
    );
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
}
