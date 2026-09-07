import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_chat_attachment.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/ai_composer_bloc.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/audio_playback_controller.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/composer/ai_attachment_tile.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/composer/ai_level_meter.dart';

/// A voice note with play/pause and a scrubbing waveform.
///
/// The hot-path rule again: the position ticks several times a second, so only
/// the part that moves sits inside the `ValueListenableBuilder`. The bloc emits
/// nothing for a position update, and the bubble around this never rebuilds.
///
/// It also asks the controller whether a tick is *about this row* before
/// reacting, which is what lets one shared player serve every voice note in the
/// conversation without a stray frame moving the wrong scrubber.
class AiAudioAttachmentRow extends StatelessWidget {
  /// Creates a row for [attachment].
  const AiAudioAttachmentRow({
    required this.attachment,
    required this.foreground,
    super.key,
  });

  /// The voice note to draw.
  final AiAudioAttachment attachment;

  /// Text colour, so the row reads correctly on a user or assistant bubble.
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AiComposerBloc>();

    return ValueListenableBuilder<AudioPlaybackValue>(
      valueListenable: bloc.playback,
      builder: (context, playback, _) {
        final isThisRow = playback.isLoaded(attachment.id);
        final isPlaying = playback.isPlaying(attachment.id);
        final progress = isThisRow ? playback.progress.fraction : 0.0;
        final elapsed = isThisRow
            ? playback.progress.position
            : attachment.duration;

        return Row(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.sm,
          children: [
            AppIconButton(
              icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              semanticLabel: isPlaying
                  ? 'ai_chat.pause'.tr()
                  : 'ai_chat.play'.tr(),
              iconColor: foreground,
              onTap: () => bloc.add(AiComposerPlaybackToggled(attachment)),
            ),
            SizedBox(
              width: 120,
              child: AiStaticWaveform(
                samples: attachment.waveform,
                progress: progress,
              ),
            ),
            Text(
              formatClock(elapsed),
              style: context.appTypography.smallNormal.copyWith(
                color: foreground,
              ),
            ),
          ],
        );
      },
    );
  }
}
