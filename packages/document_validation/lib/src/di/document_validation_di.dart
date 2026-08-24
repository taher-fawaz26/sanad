import 'package:core/core.dart';
import 'package:document_flow/document_flow.dart';
import 'package:document_validation/src/data/datasources/emirates_id_scanner_datasource.dart';
import 'package:document_validation/src/data/datasources/trade_license_ocr_datasource.dart';
import 'package:document_validation/src/data/document_type_validator_impl.dart';

/// Dependency registration for the pre-upload document-type validation gate.
///
/// Registers one app-wide [DocumentTypeValidator] — every
/// `DocumentFlowBloc` instance (registration, organization-settings legal
/// documents, …) is handed the same instance rather than each feature
/// standing up its own scanner/OCR stack.
abstract final class DocumentValidationDI {
  DocumentValidationDI._();

  static void init() {
    sl
      ..registerLazySingleton(EmiratesIdScannerDataSource.new)
      ..registerLazySingleton(TradeLicenseOcrDataSource.new)
      ..registerLazySingleton<DocumentTypeValidator>(
        () => DocumentTypeValidatorImpl(
          emiratesIdScanner: sl<EmiratesIdScannerDataSource>(),
          tradeLicenseOcr: sl<TradeLicenseOcrDataSource>(),
        ),
      );
  }
}
