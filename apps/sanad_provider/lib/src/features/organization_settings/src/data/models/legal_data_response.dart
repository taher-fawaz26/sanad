import 'package:sanad_provider/src/features/organization_settings/src/data/models/national_id_response.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/models/trade_license_response.dart';

/// Shared response shape for `GET legal-data` and `POST legal-data/extract` —
/// both return the same `{ personalLegalData, tradeLicenseLegalData }` pair,
/// just populated from different sources (stored vs freshly extracted).
class LegalDataResponse {
  const LegalDataResponse({this.personalLegalData, this.tradeLicenseLegalData});

  factory LegalDataResponse.fromJson(Map<String, dynamic> json) {
    final data = _unwrap(json);
    final personal = data['personalLegalData'] as Map<String, dynamic>?;
    final tradeLicense = data['tradeLicenseLegalData'] as Map<String, dynamic>?;

    return LegalDataResponse(
      personalLegalData: personal == null
          ? null
          : NationalIdResponse.fromJson(personal),
      tradeLicenseLegalData: tradeLicense == null
          ? null
          : TradeLicenseResponse.fromJson(tradeLicense),
    );
  }

  final NationalIdResponse? personalLegalData;
  final TradeLicenseResponse? tradeLicenseLegalData;

  static Map<String, dynamic> _unwrap(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    return json;
  }
}
