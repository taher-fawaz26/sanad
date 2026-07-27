import 'package:asset_picker/src/utils/asset_mime_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AssetMimeResolver', () {
    test('resolves from file name', () {
      expect(AssetMimeResolver.fromFileName('report.pdf'), 'application/pdf');
      expect(AssetMimeResolver.fromFileName('pic.PNG'), 'image/png');
    });

    test('resolves from bare extension', () {
      expect(AssetMimeResolver.fromExtension('.docx'), contains('word'));
      expect(AssetMimeResolver.fromExtension('mp4'), 'video/mp4');
    });

    test('falls back for unknown / missing extension', () {
      const fallback = AssetMimeResolver.fallback;
      expect(AssetMimeResolver.fromFileName('noext'), fallback);
      expect(AssetMimeResolver.fromExtension('zzz'), fallback);
    });
  });
}
