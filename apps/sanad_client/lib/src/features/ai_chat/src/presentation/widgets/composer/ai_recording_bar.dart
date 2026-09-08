import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_audio_recorder.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/ai_composer_bloc.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/ai_circle_icon_button.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/composer/ai_attachment_tile.dart'
    show formatClock;
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/composer/ai_level_meter.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/composer/ai_recording_gesture.dart';

/// The composer card's contents while a voice-note take is running — split
/// into the two slots the card's shell gives every state.
///
/// Both interactions share [AiRecordingContentRow]: a held take and a locked
/// one are the same capture, and showing the same clock and the same real
/// waveform for both is what makes locking read as "keep going" rather than
/// "start over". Only the second slot differs, because only the way the take
/// *ends* differs — a held take ends when the finger lifts, so it offers drag
/// affordances and no buttons; a locked take ends at an explicit control, so
/// it offers buttons and no drag.
class AiRecordingContentRow extends StatelessWidget {
  /// Creates the row.
  const AiRecordingContentRow({super.key, this.isLocked = false});

  /// Whether the take is hands-free.
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AiComposerBloc>();
    final colors = context.appColors;

    return Row(
      spacing: AppSpacing.sm,
      children: [
        _RecordingDot(color: colors.error500),
        // Only the clock and the meter sit inside the listener. The dot and
        // the lock badge do not move, and rebuilding them 8 times a second
        // would be 8 times a second of wasted layout.
        Expanded(
          child: ValueListenableBuilder<AiRecordingSample>(
            valueListenable: bloc.recordingLevel,
            builder: (context, sample, _) => Row(
              spacing: AppSpacing.sm,
              children: [
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
          ),
        ),
        if (isLocked) const _LockedBadge(),
      ],
    );
  }
}

/// The second slot while the take is held under a finger.
///
/// No buttons at all, on purpose: the finger is busy, and a control it cannot
/// reach without ending the take is a control that is not there. What it shows
/// instead is where the two drags lead, and how far along each one is.
class AiRecordingHintRow extends StatelessWidget {
  /// Creates the row driven by [drag].
  const AiRecordingHintRow({required this.drag, super.key});

  /// How far the live gesture has travelled from where it started.
  ///
  /// A [ValueListenable] and not a field: this changes with every pointer
  /// frame, and routing it through the composer's `BlocBuilder` would rebuild
  /// the card — and the text field inside it — at pointer rate.
  final ValueListenable<Offset> drag;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final direction = Directionality.of(context);

    return ValueListenableBuilder<Offset>(
      valueListenable: drag,
      builder: (context, offset, _) {
        final toCancel = AiRecordingGesture.cancelProgress(offset, direction);
        final toLock = AiRecordingGesture.lockProgress(offset);

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Slides with the finger and darkens as it approaches, so the
            // outcome is legible before it is committed to.
            Flexible(
              child: _Hint(
                icon: Icons.chevron_left_rounded,
                label: 'ai_chat.record_slide_to_cancel'.tr(),
                // `Directionality` mirrors the glyph for us; the offset is
                // already resolved into "progress toward the leading edge".
                offset: Offset(offset.dx.clamp(-48.0, 48.0), 0),
                color: Color.lerp(colors.textSecondary, colors.error, toCancel),
              ),
            ),
            Flexible(
              child: _Hint(
                icon: Icons.lock_outline_rounded,
                label: 'ai_chat.record_slide_to_lock'.tr(),
                offset: Offset(0, offset.dy.clamp(-24.0, 0.0)),
                color: Color.lerp(colors.textSecondary, colors.primary, toLock),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The second slot once the take is locked — the finger is free, so this is
/// where the take's controls live.
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
          semanticLabel: 'ai_chat.record_delete'.tr(),
          iconColor: colors.error,
          onTap: () => bloc.add(const AiComposerRecordingCancelled()),
        ),
        AiCircleIconButton(
          icon: Icons.stop_rounded,
          semanticLabel: 'ai_chat.record_finish'.tr(),
          background: colors.primary,
          iconColor: colors.onPrimary,
          onTap: () => bloc.add(const AiComposerRecordingStopped()),
        ),
      ],
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({
    required this.icon,
    required this.label,
    required this.offset,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Offset offset;
  final Color? color;

  @override
  Widget build(BuildContext context) => Transform.translate(
    offset: offset,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.xs,
      children: [
        Icon(icon, size: 16, color: color),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.appTypography.smallNormal.copyWith(color: color),
          ),
        ),
      ],
    ),
  );
}

/// The "hands-free" marker, shown only once the take is locked.
class _LockedBadge extends StatelessWidget {
  const _LockedBadge();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Semantics(
      label: 'ai_chat.record_locked'.tr(),
      liveRegion: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          borderRadius: AppRadius.circularXxl,
        ),
        child: ExcludeSemantics(
          child: Icon(
            Icons.lock_rounded,
            size: 14,
            color: colors.primary,
          ),
        ),
      ),
    );
  }
}

/// The "we are recording" indicator.
///
/// A plain filled circle, not a pulse: a repeating animation here would run a
/// ticker for the whole take and, per the testing rules, would make every
/// widget test that touches this screen unable to use `pumpAndSettle`. The
/// waveform beside it is already live, real, and a far better signal that the
/// microphone is open than a blinking dot would be.
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
