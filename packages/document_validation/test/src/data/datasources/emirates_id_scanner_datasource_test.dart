import 'package:document_validation/src/data/datasources/emirates_id_scanner_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmiratesIdScannerDataSource', () {
    test(
      'an unreadable/nonexistent file path is an engine error, not a '
      'confident rejection',
      () async {
        final dataSource = EmiratesIdScannerDataSource();

        final result = await dataSource.looksLikeEmiratesId(
          '/nonexistent/path/does-not-exist.jpg',
        );

        expect(result, isNull);
      },
    );
  });
}
