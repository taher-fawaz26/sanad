import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_audio_recorder.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/ai_composer_bloc.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/ai_circle_icon_button.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/composer/ai_attachment_tile.dart'
    show formatClock;
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/composer/ai_level_meter.dart';

/// The composer card's content while a voice-note take is running — split
/// into [AiRecordingContentRow] (elapsed time + the real level meter) and
/// [AiRecordingActionsRow] (cancel + stop), the two slots the card's shell
/// gives every state.
///
/// No attach button here, unlike dictation's actions row: Figma shows no
/// frame for this state, and backgrounding mid-recording already aborts the
/// take and deletes its partial file (see `AiComposerBloc._onBackgrounded`) —
/// changing this state's affordances is exactly the recording-lifecycle
/// change the brief says not to make without a proven need.
///
/// Temporary UI. The final design is not approved, so this is built from
/// design-system components and is meant to be replaced without any of the
/// logic above it moving.
class AiRecordingContentRow extends StatelessWidget {
  /// Creates the row.
  const AiRecordingContentRow({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AiComposerBloc>();
    final colors = context.appColors;

    return ValueListenableBuilder<AiRecordingSample>(
      valueListenable: bloc.recordingLevel,
      builder: (context, sample, _) => Row(
        spacing: AppSpacing.sm,
        children: [
          _RecordingDot(color: colors.error500),
          SizedBox(
            width: 44,
            child: Text(
              formatClock(sample.elapsed),
              style: context.appTypography.regularNormal.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: AiLevelMeter(
              levels: bloc.recordingLevel.history,
              height: 24,
              color: colors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// The composer card's actions row while a voice-note take is running.
class AiRecordingActionsRow extends StatelessWidget {
  /// Creates the row.
  const AiRecordingActionsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AiComposerBloc>();
    final colors = context.appColors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AiCircleIconButton(
          icon: Icons.delete_outline_rounded,
          semanticLabel: 'ai_chat.record_cancel'.tr(),
          iconColor: colors.error,
          onTap: () => bloc.add(const AiComposerRecordingCancelled()),
        ),
        AiCircleIconButton(
          icon: Icons.stop_rounded,
          semanticLabel: 'ai_chat.record_stop'.tr(),
          background: colors.primary,
          iconColor: colors.onPrimary,
          onTap: () => bloc.add(const AiComposerRecordingStopped()),
        ),
      ],
    );
  }
}

/// The "we are recording" indicator.
///
/// A plain filled circle, not a pulse: a repeating animation here would run a
/// ticker for the whole take and, per the testing rules, would make every
/// widget test that touches this screen unable to use `pumpAndSettle`.
class _RecordingDot extends StatelessWidget {
  const _RecordingDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'ai_chat.recording_in_progress'.tr(),
    liveRegion: true,
    child: Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    ),
  );
}
