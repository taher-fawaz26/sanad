import 'dart:typed_data';

import 'package:asset_picker/asset_picker.dart';
import 'package:asset_picker/src/infrastructure/compression/asset_image_compressor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

Uint8List _pngBytes({int width = 32, int height = 32}) {
  final image = img.Image(width: width, height: height);
  // Fill with a solid color so it encodes to a non-trivial payload.
  img.fill(image, color: img.ColorRgb8(200, 30, 30));
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  group('ImagePackageAssetCompressor.encodeJpeg', () {
    test('re-encodes a decodable image to JPEG bytes', () {
      final png = _pngBytes();

      final jpeg = ImagePackageAssetCompressor.encodeJpeg(png, 85);

      expect(jpeg, isNotNull);
      // Output must be valid JPEG (decodes, and carries the JPEG SOI marker).
      expect(jpeg!.sublist(0, 2), [0xFF, 0xD8]);
      expect(img.decodeJpg(jpeg), isNotNull);
    });

    test('returns null for undecodable bytes (e.g. SVG/garbage)', () {
      final garbage = Uint8List.fromList([1, 2, 3, 4, 5]);

      expect(ImagePackageAssetCompressor.encodeJpeg(garbage, 85), isNull);
    });
  });

  group('ImagePackageAssetCompressor.toJpgName', () {
    test('swaps any extension for .jpg', () {
      expect(ImagePackageAssetCompressor.toJpgName('photo.png'), 'photo.jpg');
      expect(ImagePackageAssetCompressor.toJpgName('a.b.heic'), 'a.b.jpg');
      expect(ImagePackageAssetCompressor.toJpgName('noext'), 'noext.jpg');
    });
  });

  group('compress', () {
    const compressor = ImagePackageAssetCompressor();

    test('re-encodes an in-memory image asset to JPEG', () async {
      final asset = PickedAsset(
        name: 'photo.png',
        path: '',
        bytes: _pngBytes(),
        mimeType: 'image/png',
        size: _pngBytes().length,
        assetType: AssetType.image,
      );

      final result = await compressor.compress(asset, quality: 85);

      expect(result.mimeType, 'image/jpeg');
      expect(result.name, 'photo.jpg');
      expect(result.bytes, isNotNull);
      expect(result.size, result.bytes!.length);
    });

    test('passes a non-image asset through untouched', () async {
      const asset = PickedAsset(
        name: 'doc.pdf',
        path: '/tmp/doc.pdf',
        mimeType: 'application/pdf',
        size: 1234,
        assetType: AssetType.pdf,
      );

      final result = await compressor.compress(asset, quality: 85);

      expect(result, asset);
    });

    test('falls back to the original when bytes cannot be decoded', () async {
      final asset = PickedAsset(
        name: 'weird.svg',
        path: '',
        bytes: Uint8List.fromList([1, 2, 3]),
        mimeType: 'image/svg+xml',
        size: 3,
        assetType: AssetType.image,
      );

      final result = await compressor.compress(asset, quality: 85);

      expect(result, asset);
    });
  });
}
