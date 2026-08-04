import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:media/src/processing/media_image_processor.dart';

void main() {
  // A 200x100 solid image encoded as PNG, used as the source bytes.
  final source = img.encodePng(
    img.Image(width: 200, height: 100)..clear(img.ColorRgb8(10, 20, 30)),
  );

  group('MediaImageProcessor.process', () {
    test('resizes down to fit the configured max dimensions', () async {
      final result = await MediaImageProcessor.process(
        MediaProcessRequest(
          bytes: source,
          rotationDegrees: 0,
          flipHorizontal: false,
          flipVertical: false,
          compressQuality: 80,
          png: false,
          maxWidth: 100,
          maxHeight: 100,
        ),
      );

      // 200x100 capped at 100x100 → scale 0.5 → 100x50.
      expect(result.width, 100);
      expect(result.height, 50);
      expect(result.bytes, isNotEmpty);
    });

    test('crops to the requested rect before resizing', () async {
      final result = await MediaImageProcessor.process(
        MediaProcessRequest(
          bytes: source,
          cropX: 0,
          cropY: 0,
          cropWidth: 50,
          cropHeight: 50,
          rotationDegrees: 0,
          flipHorizontal: false,
          flipVertical: false,
          compressQuality: 80,
          png: false,
        ),
      );

      expect(result.width, 50);
      expect(result.height, 50);
    });

    test('90° rotation swaps width and height', () async {
      final result = await MediaImageProcessor.process(
        MediaProcessRequest(
          bytes: source,
          rotationDegrees: 90,
          flipHorizontal: false,
          flipVertical: false,
          compressQuality: 80,
          png: false,
        ),
      );

      expect(result.width, 100);
      expect(result.height, 200);
    });

    test('leaves dimensions untouched when already within bounds', () async {
      final result = await MediaImageProcessor.process(
        MediaProcessRequest(
          bytes: source,
          rotationDegrees: 0,
          flipHorizontal: false,
          flipVertical: false,
          compressQuality: 80,
          png: false,
          maxWidth: 4000,
          maxHeight: 4000,
        ),
      );

      expect(result.width, 200);
      expect(result.height, 100);
    });

    test('throws MediaProcessingException on undecodable bytes', () async {
      expect(
        () => MediaImageProcessor.process(
          MediaProcessRequest(
            bytes: img.encodePng(img.Image(width: 1, height: 1)).sublist(0, 4),
            rotationDegrees: 0,
            flipHorizontal: false,
            flipVertical: false,
            compressQuality: 80,
            png: false,
          ),
        ),
        throwsA(isA<MediaProcessingException>()),
      );
    });
  });
}
