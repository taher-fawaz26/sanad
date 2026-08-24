import 'package:asset_picker/asset_picker.dart';
import 'package:document_flow/document_flow.dart';
import 'package:document_validation/src/data/datasources/emirates_id_scanner_datasource.dart';
import 'package:document_validation/src/data/datasources/trade_license_ocr_datasource.dart';

/// The app-wide [DocumentTypeValidator]: dispatches to the right local
/// engine by [DocumentType] and normalizes each engine's tri-state result
/// (`true`/`false`/`null`) into a [DocumentValidationResult].
///
/// Document types with no configured engine pass through as
/// [DocumentValidationResult.valid] — this is a pre-upload gate for the two
/// types the product currently requires (§1/§2 of the feature spec), not a
/// universal classifier; onboarding a new gated type means adding a case
/// here, not changing this class's shape.
class DocumentTypeValidatorImpl implements DocumentTypeValidator {
  const DocumentTypeValidatorImpl({
    required EmiratesIdScannerDataSource emiratesIdScanner,
    required TradeLicenseOcrDataSource tradeLicenseOcr,
  }) : _emiratesIdScanner = emiratesIdScanner,
       _tradeLicenseOcr = tradeLicenseOcr;

  final EmiratesIdScannerDataSource _emiratesIdScanner;
  final TradeLicenseOcrDataSource _tradeLicenseOcr;

  @override
  Future<DocumentValidationResult> validate(
    PickedAsset asset, {
    required DocumentType type,
  }) async {
    final looksLikeExpectedType = switch (type) {
      DocumentType.emiratesIdFront ||
      DocumentType.emiratesIdBack => await _emiratesIdScanner
          .looksLikeEmiratesId(asset.path),
      DocumentType.tradeLicense => await _tradeLicenseOcr
          .looksLikeTradeLicense(asset.path),
      DocumentType.passport ||
      DocumentType.vehicleLicense ||
      DocumentType.other => true,
    };

    return switch (looksLikeExpectedType) {
      true => const DocumentValidationResult.valid(),
      false => const DocumentValidationResult.invalid(),
      null => const DocumentValidationResult.error(),
    };
  }
}
