import 'package:ai_ui_renderer/ai_ui_renderer.dart';
import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/ai_chat_message.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_chat_attachment.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/active_stream_controller.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/composer/ai_attachment_tile.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/composer/ai_audio_attachment_row.dart';

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

  /// Figma `Chat – 02 Reply` (`7137:30295`) metrics for the two rows.
  static const _rowGap = 8.0;
  static const _userMaxWidth = 300.0;
  static const _avatarSize = 40.0;
  static const _aiMarkSize = 24.0;

  @override
  Widget build(BuildContext context) => _isUser
      ? _UserRow(
          gap: _rowGap,
          maxWidth: _userMaxWidth,
          avatarSize: _avatarSize,
          child: _Content(
            message: message,
            activeStream: activeStream,
            isUser: true,
          ),
        )
      : _AssistantRow(
          gap: _rowGap,
          markSize: _aiMarkSize,
          child: _Content(
            message: message,
            activeStream: activeStream,
            isUser: false,
          ),
        );
}

/// The user's turn — Figma `7137:30372`: the bubble pushed to the trailing
/// edge with the account portrait beside it, bottoms aligned.
///
/// The bubble's trailing bottom corner is clipped to 4dp while the other
/// three stay at 24 — a tail pointing at the avatar. Expressed with
/// `BorderRadiusDirectional`, so under RTL the notch mirrors to the other
/// side and keeps pointing at the portrait rather than away from it.
class _UserRow extends StatelessWidget {
  const _UserRow({
    required this.gap,
    required this.maxWidth,
    required this.avatarSize,
    required this.child,
  });

  final double gap;
  final double maxWidth;
  final double avatarSize;
  final Widget child;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.end,
    crossAxisAlignment: CrossAxisAlignment.end,
    spacing: gap,
    children: [
      Flexible(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.lg,
            ),
            decoration: const BoxDecoration(
              // Figma `#127A60`. A literal for the same reason the page wash
              // is: the palette's nearest neighbours (`shade700` `#1A7E6B`,
              // `shade800` `#126153`) are both visibly off it, and this is
              // the user's own voice on the screen.
              color: Color(0xFF127A60),
              borderRadius: BorderRadiusDirectional.only(
                topStart: Radius.circular(24),
                topEnd: Radius.circular(24),
                bottomStart: Radius.circular(24),
                bottomEnd: Radius.circular(4),
              ),
            ),
            child: child,
          ),
        ),
      ),
      _UserAvatar(size: avatarSize),
    ],
  );
}

/// The account portrait beside the user's turn — Figma `avatar`
/// (`6695:44807`), 40dp.
///
/// Same placeholder as the header's, and the same caveat: it stands in until
/// the profile API supplies the signed-in user's own image.
class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SizedBox.square(
      dimension: size,
      child: ClipOval(
        child: Image.asset(
          AppImages.aiChatProfileAvatarPlaceholder,
          package: AppAssets.package,
          fit: BoxFit.cover,
          cacheWidth: (size * 3).round(),
          errorBuilder: (context, _, _) => ColoredBox(
            color: colors.controlFill,
            child: Icon(
              Icons.person_outline_rounded,
              color: colors.textSecondary,
              size: size * 0.55,
            ),
          ),
        ),
      ),
    );
  }
}

/// The assistant's turn — Figma `AI Message Row` (`7153:30987`): the Sanad
/// mark outside the bubble at its leading edge, tops aligned, the bubble
/// taking the rest of the row.
///
/// The bubble is plain white with a 16dp radius and no border — on the page's
/// green wash the surface alone separates it, and the border the previous
/// version drew made every reply look like a form field.
class _AssistantRow extends StatelessWidget {
  const _AssistantRow({
    required this.gap,
    required this.markSize,
    required this.child,
  });

  final double gap;
  final double markSize;
  final Widget child;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: gap,
    children: [
      SvgPicture.asset(
        AppSvgs.aiChatSparkle,
        package: AppAssets.package,
        width: markSize,
        height: markSize,
      ),
      Expanded(
        child: Container(
          padding: EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: context.appColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: child,
        ),
      ),
    ],
  );
}

/// What sits inside either bubble. Unchanged in behaviour — attachments above
/// the caption, then the text, then any structured UI the agent sent.
class _Content extends StatelessWidget {
  const _Content({
    required this.message,
    required this.activeStream,
    required this.isUser,
  });

  final AiChatMessage message;
  final ActiveStreamController activeStream;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final foreground = isUser ? colors.onPrimary : colors.textPrimary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.sm,
      children: [
        // Attachments read above the caption, the way they do in every
        // chat: the photo is the subject and the text is about it.
        if (message.hasAttachments)
          _Attachments(
            attachments: message.attachments,
            foreground: foreground,
          ),
        _Text(
          message: message,
          activeStream: activeStream,
          color: foreground,
        ),
        if (message.hasUi) AiUiSurface(document: message.document!),
      ],
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
            : _prose(context, text, style),
      );
    }

    if (message.text.isEmpty) return const SizedBox.shrink();
    return _prose(context, message.text, style);
  }

  /// Renders one piece of prose, honouring Markdown in an assistant reply.
  ///
  /// The agent's streaming endpoint emits **only** prose — it sends no `ui`
  /// event — and that prose is heavily Markdown: bold, headings, numbered
  /// lists. Without this the reader sees literal asterisks. This is the same
  /// policy the protocol already states for `text` nodes, applied to the
  /// bubble's own text so a transport that never sends `ui` still reads
  /// correctly.
  ///
  /// A user message is never parsed: it is what the person typed, and turning
  /// their asterisks into bold would be putting words in their mouth.
  ///
  /// [AiUiMarkdown.build] returns null when there is no markup — the common
  /// case, decided by one regex — so plain prose stays on the plain [Text]
  /// path and this stays cheap enough to run per delta.
  Widget _prose(BuildContext context, String text, TextStyle style) {
    if (message.role == AiChatRole.user) return Text(text, style: style);
    return AiUiMarkdown.build(context, text, baseStyle: style) ??
        Text(text, style: style);
  }
}

/// The attachments carried by one message.
///
/// A voice note gets a playable row; images and documents get read-only tiles.
/// The tiles reuse the composer's, with removal wired to nothing — a sent
/// message is not editable, and a second near-identical widget would be a
/// second thing to keep in step.
class _Attachments extends StatelessWidget {
  const _Attachments({required this.attachments, required this.foreground});

  final List<AiChatAttachment> attachments;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final audio = attachments.whereType<AiAudioAttachment>().toList();
    final visual = attachments.where((a) => a is! AiAudioAttachment).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.sm,
      children: [
        for (final take in audio)
          AiAudioAttachmentRow(
            key: ValueKey(take.id),
            attachment: take,
            foreground: foreground,
          ),
        if (visual.isNotEmpty)
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final attachment in visual)
                AiAttachmentTile(
                  key: ValueKey(attachment.id),
                  attachment: attachment,
                  onRemove: () {},
                ),
            ],
          ),
      ],
    );
  }
}
