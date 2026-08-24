import 'package:asset_picker/asset_picker.dart';
import 'package:document_flow/document_flow.dart';
import 'package:document_validation/src/data/datasources/emirates_id_scanner_datasource.dart';
import 'package:document_validation/src/data/datasources/trade_license_ocr_datasource.dart';
import 'package:document_validation/src/data/document_type_validator_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockEmiratesIdScannerDataSource extends Mock
    implements EmiratesIdScannerDataSource {}

class _MockTradeLicenseOcrDataSource extends Mock
    implements TradeLicenseOcrDataSource {}

void main() {
  late _MockEmiratesIdScannerDataSource emiratesIdScanner;
  late _MockTradeLicenseOcrDataSource tradeLicenseOcr;
  late DocumentTypeValidatorImpl validator;

  const asset = PickedAsset(
    name: 'doc.jpg',
    path: '/tmp/doc.jpg',
    mimeType: 'image/jpeg',
    size: 1024,
    assetType: AssetType.image,
  );

  setUp(() {
    emiratesIdScanner = _MockEmiratesIdScannerDataSource();
    tradeLicenseOcr = _MockTradeLicenseOcrDataSource();
    validator = DocumentTypeValidatorImpl(
      emiratesIdScanner: emiratesIdScanner,
      tradeLicenseOcr: tradeLicenseOcr,
    );
  });

  group('DocumentTypeValidatorImpl — Emirates ID dispatch', () {
    for (final type in [
      DocumentType.emiratesIdFront,
      DocumentType.emiratesIdBack,
    ]) {
      test('$type: scanner accept -> valid', () async {
        when(
          () => emiratesIdScanner.looksLikeEmiratesId(asset.path),
        ).thenAnswer((_) async => true);

        final result = await validator.validate(asset, type: type);

        expect(result, const DocumentValidationResult.valid());
        verifyNever(() => tradeLicenseOcr.looksLikeTradeLicense(any()));
      });

      test('$type: scanner reject -> invalid', () async {
        when(
          () => emiratesIdScanner.looksLikeEmiratesId(asset.path),
        ).thenAnswer((_) async => false);

        final result = await validator.validate(asset, type: type);

        expect(result, const DocumentValidationResult.invalid());
      });

      test('$type: scanner engine failure (null) -> error', () async {
        when(
          () => emiratesIdScanner.looksLikeEmiratesId(asset.path),
        ).thenAnswer((_) async => null);

        final result = await validator.validate(asset, type: type);

        expect(result, const DocumentValidationResult.error());
      });
    }
  });

  group('DocumentTypeValidatorImpl — Trade License dispatch', () {
    test('OCR accept -> valid', () async {
      when(
        () => tradeLicenseOcr.looksLikeTradeLicense(asset.path),
      ).thenAnswer((_) async => true);

      final result = await validator.validate(
        asset,
        type: DocumentType.tradeLicense,
      );

      expect(result, const DocumentValidationResult.valid());
      verifyNever(() => emiratesIdScanner.looksLikeEmiratesId(any()));
    });

    test('OCR reject -> invalid', () async {
      when(
        () => tradeLicenseOcr.looksLikeTradeLicense(asset.path),
      ).thenAnswer((_) async => false);

      final result = await validator.validate(
        asset,
        type: DocumentType.tradeLicense,
      );

      expect(result, const DocumentValidationResult.invalid());
    });

    test('OCR engine failure (null) -> error', () async {
      when(
        () => tradeLicenseOcr.looksLikeTradeLicense(asset.path),
      ).thenAnswer((_) async => null);

      final result = await validator.validate(
        asset,
        type: DocumentType.tradeLicense,
      );

      expect(result, const DocumentValidationResult.error());
    });
  });

  test('an ungated document type always passes through as valid', () async {
    final result = await validator.validate(
      asset,
      type: DocumentType.passport,
    );

    expect(result, const DocumentValidationResult.valid());
    verifyNever(() => emiratesIdScanner.looksLikeEmiratesId(any()));
    verifyNever(() => tradeLicenseOcr.looksLikeTradeLicense(any()));
  });
}
