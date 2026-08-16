import 'package:asset_picker/src/domain/entities/asset_picker_options.dart';
import 'package:asset_picker/src/domain/entities/picked_asset.dart';
import 'package:asset_picker/src/domain/enums/asset_source.dart';
import 'package:asset_picker/src/domain/enums/asset_type.dart';
import 'package:asset_picker/src/domain/failures/asset_picker_exception.dart';
import 'package:asset_picker/src/infrastructure/providers/file_provider.dart';
import 'package:asset_picker/src/utils/asset_mime_resolver.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show PlatformException;

/// [FileProvider] backed by `file_picker`.
///
/// Supports images, PDFs, office documents, archives, and arbitrary files,
/// with optional extension filtering derived from [AssetPickerOptions]. It is
/// the only place `file_picker` is referenced in the whole application.
class FilePickerFileProvider implements FileProvider {
  const FilePickerFileProvider();

  @override
  Future<List<PickedAsset>> pick(AssetPickerOptions options) async {
    final extensions = options.resolvedAllowedExtensions;
    final useCustom = extensions != null && extensions.isNotEmpty;
    final type = useCustom ? FileType.custom : FileType.any;
    final allowedExtensions = useCustom ? extensions.toList() : null;

    try {
      final List<PlatformFile> platformFiles;
      if (options.allowMultiple) {
        final result = await FilePicker.pickFiles(
          type: type,
          allowedExtensions: allowedExtensions,
        );
        platformFiles = result;
      } else {
        final file = await FilePicker.pickFile(
          type: type,
          allowedExtensions: allowedExtensions,
        );
        platformFiles = file == null ? const [] : [file];
      }

      if (platformFiles.isEmpty) return const [];

      final limit = options.effectiveMaxSelection;
      final selected = platformFiles.length > limit
          ? platformFiles.sublist(0, limit)
          : platformFiles;

      return [
        for (final file in selected)
          await _toPickedAsset(file, loadBytes: options.loadBytes),
      ];
    } on PlatformException catch (e) {
      final code = e.code.toLowerCase();
      if (code.contains('denied') || code.contains('permission')) {
        throw AssetPermissionDeniedException(
          AssetSource.files,
          permanentlyDenied: true,
          message: e.message ?? 'File access denied.',
        );
      }
      throw AssetPickerPlatformException(
        e.message ?? 'The file picker failed.',
        source: AssetSource.files,
        cause: e,
      );
    }
  }

  Future<PickedAsset> _toPickedAsset(
    PlatformFile file, {
    required bool loadBytes,
  }) async {
    final extension = _extensionOf(file.name);
    return PickedAsset(
      name: file.name,
      path: file.path ?? '',
      bytes: loadBytes ? await file.readAsBytes() : null,
      mimeType: AssetMimeResolver.fromExtension(extension),
      size: await file.length(),
      assetType: AssetType.fromExtension(extension),
    );
  }

  String _extensionOf(String name) {
    final dot = name.lastIndexOf('.');
    return dot < 0 ? '' : name.substring(dot + 1);
  }
}
