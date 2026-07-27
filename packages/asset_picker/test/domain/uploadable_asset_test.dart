import 'package:asset_picker/asset_picker.dart';
import 'package:flutter_test/flutter_test.dart';

const _asset = PickedAsset(
  name: 'photo.jpg',
  path: '/tmp/photo.jpg',
  mimeType: 'image/jpeg',
  size: 100,
  assetType: AssetType.image,
);

void main() {
  group('UploadStatus', () {
    test('flags describe each state', () {
      expect(UploadStatus.uploaded.isUploaded, isTrue);
      expect(UploadStatus.uploading.isUploading, isTrue);
      expect(UploadStatus.failed.isFailed, isTrue);
      expect(UploadStatus.pending.isWaiting, isTrue);
      expect(UploadStatus.retry.isWaiting, isTrue);
    });

    test('canStart from pending, retry, failed only', () {
      expect(UploadStatus.pending.canStart, isTrue);
      expect(UploadStatus.retry.canStart, isTrue);
      expect(UploadStatus.failed.canStart, isTrue);
      expect(UploadStatus.uploading.canStart, isFalse);
      expect(UploadStatus.uploaded.canStart, isFalse);
    });
  });

  group('UploadableAsset', () {
    test('defaults to pending with zero progress', () {
      const uploadable = UploadableAsset(asset: _asset);
      expect(uploadable.status, UploadStatus.pending);
      expect(uploadable.progress, 0.0);
      expect(uploadable.error, isNull);
    });

    test('markUploading sets progress and clears error', () {
      final u = const UploadableAsset(
        asset: _asset,
        status: UploadStatus.failed,
        error: 'boom',
      ).markUploading(0.4);
      expect(u.status, UploadStatus.uploading);
      expect(u.progress, 0.4);
      expect(u.error, isNull);
    });

    test('markUploaded records backend identifiers', () {
      final u = const UploadableAsset(asset: _asset).markUploaded(
        remoteId: 'abc',
        remoteUrl: 'https://cdn/abc.jpg',
      );
      expect(u.status, UploadStatus.uploaded);
      expect(u.progress, 1.0);
      expect(u.remoteId, 'abc');
      expect(u.remoteUrl, 'https://cdn/abc.jpg');
    });

    test('markFailed carries the error message', () {
      final u = const UploadableAsset(asset: _asset).markFailed('no network');
      expect(u.status, UploadStatus.failed);
      expect(u.error, 'no network');
    });

    test('markRetry clears error and resets progress', () {
      final u = const UploadableAsset(
        asset: _asset,
      ).markFailed('x').markRetry();
      expect(u.status, UploadStatus.retry);
      expect(u.error, isNull);
      expect(u.progress, 0.0);
    });

    test('copyWith preserves error unless explicitly changed', () {
      final failed = const UploadableAsset(asset: _asset).markFailed('x');
      final sameProgress = failed.copyWith(progress: 0.1);
      expect(sameProgress.error, 'x');
      final cleared = failed.copyWith(error: null);
      expect(cleared.error, isNull);
    });

    test('PickedAsset.toUploadable lifts into a pending wrapper', () {
      expect(_asset.toUploadable().status, UploadStatus.pending);
      expect([_asset].toUploadable().single.asset, _asset);
    });
  });
}
