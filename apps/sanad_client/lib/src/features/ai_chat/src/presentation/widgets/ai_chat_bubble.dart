import 'package:ai_ui_renderer/ai_ui_renderer.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/ai_chat_message.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/active_stream_controller.dart';

/// One message.
///
/// Structured UI renders *inside* the assistant bubble via [AiUiSurface] — it
/// is part of the reply, not a separate surface bolted underneath it.
class AiChatBubble extends StatelessWidget {
  /// Creates a bubble for [message].
  const AiChatBubble({
    required this.message,
    required this.activeStream,
    super.key,
  });

  /// The message to draw.
  final AiChatMessage message;

  /// Source of streaming text while [message] is still being written.
  final ActiveStreamController activeStream;

  bool get _isUser => message.role == AiChatRole.user;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Align(
      alignment: _isUser
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.85,
        ),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: _isUser ? colors.primary : colors.surface,
            borderRadius: AppRadius.circularMd,
            border: _isUser ? null : Border.all(color: colors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.sm,
            children: [
              _Text(
                message: message,
                activeStream: activeStream,
                color: _isUser ? colors.onPrimary : colors.textPrimary,
              ),
              if (message.hasUi) AiUiSurface(document: message.document!),
            ],
          ),
        ),
      ),
    );
  }
}

class _Text extends StatelessWidget {
  const _Text({
    required this.message,
    required this.activeStream,
    required this.color,
  });

  final AiChatMessage message;
  final ActiveStreamController activeStream;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final style = context.appTypography.regularNormal.copyWith(color: color);

    // The performance-critical branch. While streaming, this bubble listens to
    // the controller directly, so a `text_delta` rebuilds *this widget only* —
    // the bloc emits no state and the message list is untouched.
    if (message.isStreaming) {
      return ValueListenableBuilder<String>(
        valueListenable: activeStream,
        builder: (context, text, _) => text.isEmpty
            ? const AppLoadingIndicator(size: 20)
            : Text(text, style: style),
      );
    }

    if (message.text.isEmpty) return const SizedBox.shrink();
    return Text(message.text, style: style);
  }
}
