import 'package:document_validation/src/data/datasources/trade_license_ocr_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TradeLicenseOcrDataSource', () {
    test(
      'an unreadable/nonexistent file path is an engine error, not a '
      'confident rejection',
      () async {
        final dataSource = TradeLicenseOcrDataSource();

        final result = await dataSource.looksLikeTradeLicense(
          '/nonexistent/path/does-not-exist.jpg',
        );

        expect(result, isNull);
      },
    );
  });
}
