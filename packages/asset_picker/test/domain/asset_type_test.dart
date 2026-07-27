import 'package:asset_picker/asset_picker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AssetType.fromExtension', () {
    test('resolves images', () {
      expect(AssetType.fromExtension('jpg'), AssetType.image);
      expect(AssetType.fromExtension('.PNG'), AssetType.image);
    });

    test('resolves pdf and documents', () {
      expect(AssetType.fromExtension('pdf'), AssetType.pdf);
      expect(AssetType.fromExtension('docx'), AssetType.document);
    });

    test('falls back to any for unknown extensions', () {
      expect(AssetType.fromExtension('xyz'), AssetType.any);
    });
  });

  group('AssetType.fromMimeType', () {
    test('maps prefixes and pdf', () {
      expect(AssetType.fromMimeType('image/jpeg'), AssetType.image);
      expect(AssetType.fromMimeType('video/mp4'), AssetType.video);
      expect(AssetType.fromMimeType('audio/mpeg'), AssetType.audio);
      expect(AssetType.fromMimeType('application/pdf'), AssetType.pdf);
      expect(AssetType.fromMimeType('text/plain'), AssetType.document);
    });

    test('falls back to any for unknown mime types', () {
      expect(AssetType.fromMimeType('weird/thing'), AssetType.any);
    });
  });

  test('any has no default extensions', () {
    expect(AssetType.any.defaultExtensions, isEmpty);
  });
}
