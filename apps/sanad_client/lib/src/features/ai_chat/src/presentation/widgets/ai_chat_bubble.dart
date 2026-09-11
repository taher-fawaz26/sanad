import 'package:ai_ui_renderer/ai_ui_renderer.dart';
import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/ai_chat_message.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_chat_attachment.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/active_stream_controller.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/composer/ai_attachment_tile.dart';
import 'package:sanad_client/src/ui/text/auto_text_direction.dart';

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
    this.onRetry,
  });

  /// The message to draw.
  final AiChatMessage message;

  /// Source of streaming text while [message] is still being written.
  final ActiveStreamController activeStream;

  /// Sends this turn again. Only offered on a user turn that failed or is
  /// still queued offline (A-03).
  final VoidCallback? onRetry;

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
          status: message.status,
          onRetry: onRetry,
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
    required this.status,
    required this.child,
    this.onRetry,
  });

  final double gap;
  final double maxWidth;
  final double avatarSize;
  final AiChatMessageStatus status;
  final VoidCallback? onRetry;
  final Widget child;

  /// Figma `#127A60`. A literal for the same reason the page wash is: the
  /// palette's nearest neighbours (`shade700` `#1A7E6B`, `shade800` `#126153`)
  /// are both visibly off it, and this is the user's own voice on the screen.
  static const _delivered = Color(0xFF127A60);

  /// The fill says which of the three things happened to this turn.
  ///
  /// Colour rather than only a footer, because the reference design changes
  /// the bubble itself: a turn held offline is visibly *set aside* (the
  /// neutral sky tone) and one that failed is visibly *wrong* (error), where a
  /// green bubble with small grey text under it reads as delivered at a
  /// glance. Both come from the palette; neither is a one-off.
  Color _fill(BuildContext context) => switch (status) {
    AiChatMessageStatus.failed => context.appColors.error,
    AiChatMessageStatus.queued => context.appColors.palettes.sky.shade500,
    _ => _delivered,
  };

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.end,
    crossAxisAlignment: CrossAxisAlignment.end,
    spacing: gap,
    children: [
      Flexible(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.lg,
                ),
                decoration: BoxDecoration(
                  color: _fill(context),
                  borderRadius: const BorderRadiusDirectional.only(
                    topStart: Radius.circular(24),
                    topEnd: Radius.circular(24),
                    bottomStart: Radius.circular(24),
                    bottomEnd: Radius.circular(4),
                  ),
                ),
                child: Opacity(
                  // A turn still on its way reads as slightly held back. Subtle
                  // on purpose: it is a hint, not an error. A queued turn keeps
                  // full opacity — its own fill already says it is waiting, and
                  // fading it as well would make it hard to read.
                  opacity: status.isSending ? 0.72 : 1,
                  child: child,
                ),
              ),
            ),
            if (status.isFailed) ...[
              SizedBox(height: AppSpacing.xs),
              _UndeliveredFooter(onRetry: onRetry),
            ] else if (status.isQueued) ...[
              SizedBox(height: AppSpacing.xs),
              const _QueuedFooter(),
            ],
          ],
        ),
      ),
      _UserAvatar(size: avatarSize),
    ],
  );
}

/// Says a turn did not arrive, and offers to send it again (A-03).
///
/// Sits under the bubble rather than inside it so the message itself still
/// reads as the user wrote it — what failed is the delivery, not the text.
/// Before this, an undelivered turn was pixel-identical to a delivered one.
class _UndeliveredFooter extends StatelessWidget {
  const _UndeliveredFooter({this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.sm,
      children: [
        // Flexible so a longer translation shortens rather than overflowing —
        // the Arabic copy is half again the length of the English.
        Flexible(
          child: Text(
            'ai_chat.message_not_sent'.tr(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: typography
                .semiBold(typography.tinyNone)
                .copyWith(color: colors.error),
          ),
        ),
        if (onRetry != null)
          Flexible(
            child: GestureDetector(
              onTap: onRetry,
              behavior: HitTestBehavior.opaque,
              child: Semantics(
                button: true,
                child: Container(
                  // Figma draws Retry as a bordered pill in the error colour,
                  // not as a link: it is the one control on the row, and it
                  // has to clear the 44dp tap target a bare word does not.
                  constraints: const BoxConstraints(minHeight: 44),
                  alignment: Alignment.center,
                  padding: EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: AppRadius.circularMd,
                    border: Border.all(color: colors.error),
                  ),
                  child: Text(
                    'ai_chat.message_retry'.tr(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typography
                        .semiBold(typography.tinyNone)
                        .copyWith(color: colors.error),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Says a turn is waiting for a connection rather than that it went wrong.
///
/// The visual difference from [_UndeliveredFooter] is the whole point of the
/// pair: this one is muted and offers no Retry text, because there is nothing
/// to retry *yet* — the turn goes out on its own the moment there is signal.
class _QueuedFooter extends StatelessWidget {
  const _QueuedFooter();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.xs,
      children: [
        Icon(
          Icons.schedule_rounded,
          size: AppDimension.iconCompact,
          color: colors.textMuted,
        ),
        Flexible(
          child: Text(
            'ai_chat.message_pending_offline'.tr(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: typography.smallNormal.copyWith(color: colors.textMuted),
          ),
        ),
      ],
    );
  }
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
            // The transport uploads the files after the turn is handed over,
            // so a `sending` turn's tiles are genuinely still in flight
            // (A-21). Reuses the tile's own busy overlay rather than adding a
            // second progress affordance.
            isUploading: message.status.isSending,
          ),
        _Text(
          message: message,
          activeStream: activeStream,
          color: foreground,
        ),
        if (message.hasUi)
          // The message id rides along so an answer from any card inside this
          // document can name the question it is answering.
          AiUiSurface(
            document: message.document!,
            messageId: message.id,
          ),
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
  ///
  /// The result is laid out in the direction the *content* reads in, not the
  /// app's. An English answer under the Arabic locale used to inherit RTL, so
  /// its periods, `1.` list markers and bullets all landed on the wrong end
  /// and the reply was genuinely hard to read (A-02). A user's own turn gets
  /// the same treatment, for the same reason: they may type in either
  /// language whatever the UI is set to.
  Widget _prose(BuildContext context, String text, TextStyle style) {
    final child = message.role == AiChatRole.user
        ? Text(text, style: style)
        : AiUiMarkdown.build(context, text, baseStyle: style) ??
              Text(text, style: style);
    return AutoDirection(text: text, child: child);
  }
}

/// The attachments carried by one message.
///
/// Images and documents, as read-only tiles. There is no audio row: AI Chat
/// sends no recorded audio, so no message can carry any — speech reaches the
/// conversation as the ordinary text the recogniser produced.
///
/// The tiles reuse the composer's, with the remove affordance switched off —
/// a sent message is not editable, and a second near-identical widget would be
/// a second thing to keep in step.
class _Attachments extends StatelessWidget {
  const _Attachments({required this.attachments, this.isUploading = false});

  final List<AiChatAttachment> attachments;

  /// Whether the turn carrying these files is still on its way.
  final bool isUploading;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.sm,
    children: [
      for (final attachment in attachments)
        AiAttachmentTile(
          key: ValueKey(attachment.id),
          attachment: attachment,
          showBusy: isUploading,
          // A sent turn is not editable, so there is nothing to remove.
          showRemove: false,
          onRemove: () {},
        ),
    ],
  );
}
