import 'dart:typed_data';

import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:media/src/config/media_editor_config.dart';
import 'package:media/src/editor/crop_layer_painters.dart';
import 'package:media/src/models/edited_media.dart';
import 'package:media/src/models/media_source.dart';
import 'package:media/src/processing/media_image_processor.dart';
import 'package:media/src/utilities/discard_changes_dialog.dart';

/// Full-screen crop / zoom / pan / rotate editor.
///
/// Drives `extended_image`'s editor mode for the interactive gestures, then
/// delegates the pixel work (EXIF-normalize, crop, rotate, resize, compress)
/// to [MediaImageProcessor] on a background isolate. Returns a fully processed
/// [EditedMedia] via `Navigator.pop`, or `null` if the user backs out.
class MediaEditorPage extends StatefulWidget {
  const MediaEditorPage({
    required this.bytes,
    required this.config,
    required this.source,
    required this.originalFileName,
    super.key,
  });

  final Uint8List bytes;
  final MediaEditorConfig config;
  final MediaSource? source;
  final String originalFileName;

  static Route<EditedMedia?> route({
    required Uint8List bytes,
    required MediaEditorConfig config,
    required MediaSource? source,
    required String originalFileName,
  }) {
    return MaterialPageRoute<EditedMedia?>(
      builder: (_) => MediaEditorPage(
        bytes: bytes,
        config: config,
        source: source,
        originalFileName: originalFileName,
      ),
      fullscreenDialog: true,
    );
  }

  @override
  State<MediaEditorPage> createState() => _MediaEditorPageState();
}

class _MediaEditorPageState extends State<MediaEditorPage> {
  final _editorKey = GlobalKey<ExtendedImageEditorState>();
  bool _isProcessing = false;
  bool _hasEdits = false;

  double? get _aspectRatio => widget.config.aspectRatio;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasEdits && !_isProcessing,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || _isProcessing) return;
        final discard = await showDiscardChangesDialog(context);
        if (discard && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
          actions: [
            _ToolbarButton(
              icon: Icons.rotate_left,
              tooltip: 'media.rotate'.tr(),
              onTap: () {
                _markEdited();
                _editorKey.currentState?.rotate(degree: -90);
              },
            ),
            _ToolbarButton(
              icon: Icons.rotate_right,
              tooltip: 'media.rotate'.tr(),
              onTap: () {
                _markEdited();
                _editorKey.currentState?.rotate();
              },
            ),
            _ToolbarButton(
              icon: Icons.refresh,
              tooltip: 'media.reset'.tr(),
              onTap: () {
                setState(() => _hasEdits = false);
                _editorKey.currentState?.reset();
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: ExtendedImage.memory(
                widget.bytes,
                fit: BoxFit.contain,
                mode: ExtendedImageMode.editor,
                extendedImageEditorKey: _editorKey,
                cacheRawData: true,
                initEditorConfigHandler: (_) => EditorConfig(
                  maxScale: 8,
                  cropRectPadding: const EdgeInsets.all(24),
                  cropAspectRatio: _aspectRatio,
                  cropLayerPainter: widget.config.circleOverlay
                      ? const CircleCropLayerPainter()
                      : const EditorCropLayerPainter(),
                  editActionDetailsIsChanged: (_) => _markEdited(),
                ),
              ),
            ),
            if (_isProcessing)
              const Positioned.fill(
                child: ColoredBox(
                  color: Colors.black54,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            // Scaffold gives `bottomNavigationBar` loose constraints bounded
            // by the *whole screen height* (see Flutter's
            // Scaffold._layout: `looseConstraints = BoxConstraints.loose(size)`).
            // AppButton's internal `Center` expands to fill any finite
            // incoming constraint (it only shrink-wraps when the max is
            // unbounded) — so without this wrapper the button stretches to
            // cover the entire screen. Column(mainAxisSize.min) gives its
            // child unbounded height, matching every other place AppButton
            // is used, so it shrink-wraps to its natural pill height here too.
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppButton(
                  label: 'common.confirm'.tr(),
                  isLoading: _isProcessing,
                  onPressed: _isProcessing ? null : _confirm,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _markEdited() {
    if (!_hasEdits) setState(() => _hasEdits = true);
  }

  Future<void> _confirm() async {
    final editorState = _editorKey.currentState;
    final rawImageData = editorState?.rawImageData;
    if (editorState == null || rawImageData == null) return;

    setState(() => _isProcessing = true);

    try {
      // getCropRect() reaches into extended_image's internal layout state and
      // throws a null-check failure if called before the editor's first
      // layout pass has completed (e.g. a very fast tap right after the page
      // opens). `layoutRect` is the one crash-safe signal of readiness, so
      // skip cropping entirely rather than call getCropRect() in that case —
      // and keep the try/catch below as a backstop for any other timing edge
      // case, so a failure here never leaves the UI stuck on the spinner.
      final action = editorState.editAction;
      final cropRect = action?.layoutRect == null
          ? null
          : editorState.getCropRect();

      final request = MediaImageProcessor.requestFrom(
        bytes: rawImageData,
        config: widget.config,
        cropLeft: (action?.needCrop ?? false) ? cropRect?.left : null,
        cropTop: (action?.needCrop ?? false) ? cropRect?.top : null,
        cropWidth: (action?.needCrop ?? false) ? cropRect?.width : null,
        cropHeight: (action?.needCrop ?? false) ? cropRect?.height : null,
        rotationDegrees: action?.rotateDegrees.round() ?? 0,
        flipHorizontal: action?.flipY ?? false,
      );

      final processed = await MediaImageProcessor.process(request);
      if (!mounted) return;

      final baseName = widget.originalFileName.split('.').first;
      Navigator.of(context).pop(
        EditedMedia(
          bytes: processed.bytes,
          width: processed.width,
          height: processed.height,
          mimeType: widget.config.outputMimeType,
          fileName: '$baseName.${widget.config.outputExtension}',
          fileSize: processed.bytes.length,
          source: widget.source,
        ),
      );
    } on Object {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('media.processing_failed'.tr())),
      );
    }
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: Colors.white),
      tooltip: tooltip,
      onPressed: onTap,
    );
  }
}
