import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/src/rendering/ai_node_renderer.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_render_scope.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_semantics.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_tokens.dart';
import 'package:ai_ui_renderer/src/rendering/primitives/ai_ui_image_view.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

final class AiUiIconRenderer extends AiNodeRenderer<AiUiIconNode> {
  const AiUiIconRenderer();

  @override
  Widget render(
    BuildContext context,
    AiUiIconNode node,
    AiUiRenderScope scope,
  ) {
    final icon = scope.icons.build(
      node.name,
      size: AiUiTokens.iconSize(node.size),
      color: AiUiTokens.toneColor(context, node.tone),
    );
    if (icon == null) {
      // Same contract as BackendIconResolver: an icon this app's bundle does
      // not know about renders as nothing, never a crash and never a
      // placeholder glyph that looks like a bug.
      scope.diagnostics.report(
        AiUiDiagnostic(
          code: AiUiDiagnosticCode.invalidProperty,
          path: node.id,
          nodeType: AiUiNodeType.icon.wire,
          detail: 'icon name unresolved',
        ),
      );
      return const SizedBox.shrink();
    }

    return leafSemantics(label: node.a11yLabel, child: icon);
  }
}

final class AiUiImageRenderer extends AiNodeRenderer<AiUiImageNode> {
  const AiUiImageRenderer();

  @override
  Widget render(
    BuildContext context,
    AiUiImageNode node,
    AiUiRenderScope scope,
  ) {
    final ratio = AiUiTokens.aspectRatio(node.aspect);
    final content = _content(context, node, scope);

    final sized = ratio == null
        ? SizedBox(
            width: AiUiTokens.thumbSize,
            height: AiUiTokens.thumbSize,
            child: content,
          )
        : AspectRatio(aspectRatio: ratio, child: content);

    // `alt` is required by the protocol precisely so this is never empty: an
    // image the agent could not describe is dropped during validation rather
    // than rendered inaccessibly.
    return leafSemantics(
      label: node.a11yLabel ?? node.alt,
      image: true,
      child: ClipRRect(borderRadius: AppRadius.circularMd, child: sized),
    );
  }

  Widget _content(
    BuildContext context,
    AiUiImageNode node,
    AiUiRenderScope scope,
  ) => AiUiImageView(
    source: node.source,
    scope: scope,
    nodeType: AiUiNodeType.image.wire,
    nodeId: node.id,
    fit: AiUiTokens.boxFit(node.fit),
  );
}
