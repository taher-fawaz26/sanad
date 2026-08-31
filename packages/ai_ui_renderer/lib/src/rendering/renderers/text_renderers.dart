import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/src/rendering/ai_node_renderer.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_render_scope.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_semantics.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_tokens.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

final class AiUiTextRenderer extends AiNodeRenderer<AiUiTextNode> {
  const AiUiTextRenderer();

  @override
  Widget render(
    BuildContext context,
    AiUiTextNode node,
    AiUiRenderScope scope,
  ) {
    // An inherently-LTR value (phone, email, URL, reference id) is isolated so
    // a bidi-neutral leading character renders at the visual start under RTL
    // instead of being reordered to the end — the recurring SAN-770/771/775
    // bug. The agent only says *what kind* of value it is; the renderer owns
    // the direction handling.
    final text = node.direction == AiUiTextDirectionHint.ltrValue
        ? node.text.ltrIsolated
        : node.text;

    return leafSemantics(
      label: node.a11yLabel,
      child: Text(
        text,
        style: AiUiTokens.textStyle(context, node.style, node.emphasis),
        textAlign: AiUiTokens.textAlign(node.align),
        maxLines: node.maxLines,
        overflow: node.maxLines == null ? null : TextOverflow.ellipsis,
      ),
    );
  }
}

/// Inline emphasis and inline links without admitting Markdown as a UI
/// transport: the agent sends a bounded list of spans, each with a closed
/// emphasis vocabulary and an optional allowlisted action.
final class AiUiRichTextRenderer extends AiNodeRenderer<AiUiRichTextNode> {
  const AiUiRichTextRenderer();

  @override
  Widget render(
    BuildContext context,
    AiUiRichTextNode node,
    AiUiRenderScope scope,
  ) => _AiUiRichText(node: node, scope: scope);
}

/// Stateful because a [TapGestureRecognizer] attached to a [TextSpan] owns
/// native resources and must be disposed. Building them inline in a
/// `StatelessWidget` leaks one recognizer per rebuild — and a chat surface
/// rebuilds often.
class _AiUiRichText extends StatefulWidget {
  const _AiUiRichText({required this.node, required this.scope});

  final AiUiRichTextNode node;
  final AiUiRenderScope scope;

  @override
  State<_AiUiRichText> createState() => _AiUiRichTextState();
}

class _AiUiRichTextState extends State<_AiUiRichText> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final colors = context.appColors;

    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();

    return Semantics(
      label: node.a11yLabel ?? node.spans.map((s) => s.text).join(),
      child: Text.rich(
        TextSpan(
          children: [
            for (final span in node.spans)
              TextSpan(
                text: span.text,
                style:
                    AiUiTokens.textStyle(
                      context,
                      AiUiTextStyleToken.body,
                      span.emphasis,
                    ).copyWith(
                      color: span.action != null ? colors.link : null,
                      decoration: span.action != null
                          ? TextDecoration.underline
                          : null,
                    ),
                recognizer: span.action == null
                    ? null
                    : _recognizerFor(context, span.action!),
              ),
          ],
        ),
        textAlign: AiUiTokens.textAlign(node.align),
      ),
    );
  }

  TapGestureRecognizer _recognizerFor(BuildContext context, AiUiAction action) {
    final recognizer = TapGestureRecognizer()
      ..onTap = () => widget.scope.actions.dispatch(context, action);
    _recognizers.add(recognizer);
    return recognizer;
  }
}
