import 'package:asset_picker/src/domain/entities/picked_asset.dart';
import 'package:asset_picker/src/presentation/preview/asset_preview_content.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// A full-screen, generic preview page for one or more assets.
///
/// Reusable and business-agnostic: it renders each asset through
/// [AssetPreviewContent] (images are zoomable; other types show a document
/// card). When more than one asset is supplied it becomes a swipeable gallery.
///
/// Push it directly:
/// ```dart
/// Navigator.of(context).push(
///   MaterialPageRoute(builder: (_) => AssetPreviewPage(assets: myAssets)),
/// );
/// ```
class AssetPreviewPage extends StatefulWidget {
  const AssetPreviewPage({
    required this.assets,
    this.initialIndex = 0,
    this.onOpen,
    this.previewBuilder,
    this.title,
    super.key,
  });

  final List<PickedAsset> assets;
  final int initialIndex;
  final AssetOpenCallback? onOpen;
  final AssetPreviewBuilder? previewBuilder;

  /// Optional explicit title. When null and there are multiple assets, a
  /// "n / total" counter is shown instead.
  final String? title;

  @override
  State<AssetPreviewPage> createState() => _AssetPreviewPageState();
}

class _AssetPreviewPageState extends State<AssetPreviewPage> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.assets.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const onSurface = Colors.white;
    final title =
        widget.title ??
        (widget.assets.length > 1
            ? '${_index + 1} / ${widget.assets.length}'
            : null);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: onSurface,
        title: title == null
            ? null
            : Text(
                title,
                style: context.appTypography.regularNormal.copyWith(
                  color: onSurface,
                ),
              ),
        actions: [
          AppCloseIcon(onTap: () => Navigator.of(context).maybePop()),
          SizedBox(width: AppSpacing.md),
        ],
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.assets.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) => AssetPreviewContent(
          asset: widget.assets[i],
          onOpen: widget.onOpen,
          previewBuilder: widget.previewBuilder,
        ),
      ),
    );
  }
}
