import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/enums/ai_speech_status.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_speech_recognizer.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/ai_composer_bloc.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/ai_circle_icon_button.dart';

/// The composer card's content while dictation is running — split into the
/// two slots the card's shell gives every state: [AiSpeechContentRow] for the
/// text row, [AiSpeechActionsRow] for the actions row.
///
/// No waveform decoration here, on purpose: the platform recognizer surfaces
/// recognised words, never an amplitude reading, so a bar-graph next to the
/// text would be exactly the fabricated microphone activity the brief rules
/// out. The live transcript is the only truthful signal dictation has to
/// show, and it is real.
///
/// Temporary UI. The final design is not approved, so this is built from
/// design-system components and is meant to be replaced without any of the
/// logic above it moving.
class AiSpeechContentRow extends StatelessWidget {
  /// Creates the row for [status].
  const AiSpeechContentRow({required this.status, super.key});

  /// Where dictation is. Drives the placeholder label, not the text itself.
  final AiSpeechStatus status;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AiComposerBloc>();
    final colors = context.appColors;

    return Row(
      spacing: AppSpacing.sm,
      children: [
        AiCircleIconButton(
          icon: Icons.close_rounded,
          semanticLabel: 'ai_chat.speech_cancel'.tr(),
          iconColor: colors.textSecondary,
          size: 28,
          iconSize: 16,
          onTap: () => bloc.add(const AiComposerSpeechCancelled()),
        ),
        Expanded(
          child: Semantics(
            liveRegion: true,
            child: ValueListenableBuilder<AiSpeechTranscript>(
              valueListenable: bloc.transcript,
              builder: (context, transcript, _) => Text(
                transcript.text.isEmpty
                    ? _hintFor(status).tr()
                    : transcript.text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.appTypography.regularNormal.copyWith(
                  color: transcript.text.isEmpty
                      ? colors.textSecondary
                      : colors.primary,
                  fontWeight: transcript.text.isEmpty
                      ? FontWeight.normal
                      : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _hintFor(AiSpeechStatus status) => switch (status) {
    AiSpeechStatus.starting => 'ai_chat.speech_starting',
    AiSpeechStatus.finalizing => 'ai_chat.speech_finalizing',
    _ => 'ai_chat.speech_listening',
  };
}

/// The composer card's actions row while dictation is running.
///
/// Attach stays reachable, matching Figma: nothing about picking a photo or a
/// document conflicts with the microphone. Cancel lives in
/// [AiSpeechContentRow] instead of here, since Figma's row does not depict it
/// and the brief still requires it as an affordance.
class AiSpeechActionsRow extends StatelessWidget {
  /// Creates the row for [status].
  const AiSpeechActionsRow({
    required this.status,
    required this.onAttach,
    super.key,
  });

  /// Where dictation is. Only gates whether "stop" is enabled.
  final AiSpeechStatus status;

  /// Opens the attach sheet — the same one the idle composer offers.
  final VoidCallback onAttach;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AiComposerBloc>();
    final colors = context.appColors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AiCircleIconButton(
          svgAsset: AppSvgs.aiChatComposerPlus,
          semanticLabel: 'ai_chat.attach'.tr(),
          onTap: onAttach,
        ),
        AiCircleIconButton(
          icon: Icons.stop_rounded,
          semanticLabel: 'ai_chat.speech_stop'.tr(),
          background: colors.primary,
          iconColor: colors.onPrimary,
          // Disabled rather than hidden while the recogniser settles, so the
          // row does not reflow at the moment the user is reaching for it.
          onTap: status == AiSpeechStatus.listening
              ? () => bloc.add(const AiComposerSpeechStopped())
              : null,
        ),
      ],
    );
  }
}
