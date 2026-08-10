import 'package:organization_settings/src/data/models/national_id_extraction_response.dart';
import 'package:organization_settings/src/data/models/trade_license_extraction_response.dart';

/// Mirrors `LegalDataExtractionResponseDto` exactly — the response of
/// `POST service-provider/legal-data/extract`.
///
/// Genuinely different from [LegalDataResponse] (the persisted-record
/// shape shared by `GET legal-data` and `PUT legal-data/documents`):
/// `personalLegalData` is required/non-nullable here, and both nested
/// objects are the leaner `*ExtractionDto` shapes (no
/// `id`/`createdAt`/`updatedAt`/media, plus a `missingFields` array).
class LegalDataExtractionResponse {
  const LegalDataExtractionResponse({
    required this.personalLegalData,
    this.tradeLicenseLegalData,
  });

  factory LegalDataExtractionResponse.fromJson(Map<String, dynamic> json) {
    final data = _unwrap(json);
    final tradeLicense = data['tradeLicenseLegalData'] as Map<String, dynamic>?;

    return LegalDataExtractionResponse(
      personalLegalData: NationalIdExtractionResponse.fromJson(
        data['personalLegalData'] as Map<String, dynamic>,
      ),
      tradeLicenseLegalData: tradeLicense == null
          ? null
          : TradeLicenseExtractionResponse.fromJson(tradeLicense),
    );
  }

  final NationalIdExtractionResponse personalLegalData;
  final TradeLicenseExtractionResponse? tradeLicenseLegalData;

  static Map<String, dynamic> _unwrap(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    return json;
  }
}
