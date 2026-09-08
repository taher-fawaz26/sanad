import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_chat_attachment.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/ai_composer_bloc.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/audio_playback_controller.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/ai_circle_icon_button.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/composer/ai_attachment_tile.dart'
    show formatClock;
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/composer/ai_level_meter.dart';

/// The finished take, before it is sent — Figma's `Audio Preview` state.
///
/// The same player, the same controller and the same waveform the conversation
/// uses for a sent voice note (see `AiAudioAttachmentRow`): a draft and a
/// message are the same audio, so hearing them back must not be two different
/// pieces of machinery. It is a separate widget only because the draft has two
/// affordances a sent note does not — discard, and send.
///
/// The hot-path rule holds here as everywhere: the position ticks several
/// times a second, so only the part that moves sits inside the
/// [ValueListenableBuilder] and the bloc emits nothing for it.
class AiAudioPreviewRow extends StatelessWidget {
  /// Creates the preview for [attachment].
  const AiAudioPreviewRow({required this.attachment, super.key});

  /// The take under preview.
  final AiAudioAttachment attachment;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AiComposerBloc>();
    final colors = context.appColors;

    return Semantics(
      label: 'ai_chat.record_preview'.tr(),
      // Without this the row's own label merges the play control and the
      // duration into one node, and the play button loses the name that is its
      // only name. The row announces what this is; the controls keep theirs.
      explicitChildNodes: true,
      child: ValueListenableBuilder<AudioPlaybackValue>(
        valueListenable: bloc.playback,
        builder: (context, playback, _) {
          final isPlaying = playback.isPlaying(attachment.id);
          final isThisTake = playback.isLoaded(attachment.id);

          return Row(
            spacing: AppSpacing.sm,
            children: [
              AiCircleIconButton(
                icon: isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                semanticLabel: isPlaying
                    ? 'ai_chat.pause'.tr()
                    : 'ai_chat.play'.tr(),
                background: colors.surfaceVariant,
                iconColor: colors.primary,
                onTap: () => bloc.add(AiComposerPlaybackToggled(attachment)),
              ),
              Expanded(
                child: AiStaticWaveform(
                  samples: attachment.waveform,
                  progress: isThisTake ? playback.progress.fraction : 0,
                ),
              ),
              Text(
                // Counts up while playing and shows the take's full length
                // when it is not — the reading a voice note gives everywhere
                // else in the app.
                formatClock(
                  isThisTake ? playback.progress.position : attachment.duration,
                ),
                style: context.appTypography.smallNormal.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
