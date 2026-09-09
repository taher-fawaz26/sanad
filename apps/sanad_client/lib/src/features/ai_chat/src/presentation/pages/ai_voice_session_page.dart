import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/enums/ai_voice_session_status.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/ai_voice_session_bloc.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/voice/ai_voice_hero.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/voice/ai_voice_interaction_panel.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/voice/ai_voice_waveform.dart';

/// The Live Voice surface — Figma `Chat – 06/07/08`
/// (`7137:29887` / `7880:16671` / `7873:16622`).
///
/// ## One control
///
/// The whole conversation runs from a single circular button whose meaning
/// comes from the session status, plus a close (X) in the top safe area.
/// There is no separate start/stop pair, no mute button and no end-call
/// button — the previous build had three, which is what made the turn
/// lifecycle ambiguous.
///
/// Every tap maps onto an event the bloc already owns
/// (see [_VoiceAction.of]); nothing about the turn is decided here.
///
/// ## What deliberately is not in this widget
///
/// Microphone level. It ticks many times a second and lives in
/// `AiVoiceSessionBloc.level`, a `ValueListenable` outside Bloc state, which
/// `AiVoiceWaveform` subscribes to on its own. A frame of audio repaints one
/// painter and nothing else on this screen.
class AiVoiceSessionPage extends StatelessWidget {
  /// Creates the page.
  const AiVoiceSessionPage({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    // No `appBar`. Figma has no toolbar here — the close control floats on
    // the gradient, which has to run edge to edge behind the status bar.
    backgroundColor: Colors.transparent,
    body: _VoiceBackdrop(child: SafeArea(child: _VoiceBody())),
  );
}

/// The immersive dark-green ground — Figma's
/// `linear-gradient(126.66deg, #10412F 0%, #000000 100%)`.
///
/// Static and `const`: it is the one layer on this screen that should not
/// move, so it costs nothing per frame while the hero and waveform animate
/// above it.
class _VoiceBackdrop extends StatelessWidget {
  const _VoiceBackdrop({required this.child});

  /// Figma's stops. Directional so the diagonal mirrors under RTL.
  static const _from = Color(0xFF10412F);
  static const _to = Color(0xFF000000);
  static const AlignmentGeometry _begin = AlignmentDirectional.topStart;
  static const AlignmentGeometry _end = AlignmentDirectional.bottomEnd;

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: _begin,
        end: _end,
        colors: [_from, _to],
      ),
    ),
    child: child,
  );
}

class _VoiceBody extends StatelessWidget {
  const _VoiceBody();

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<AiVoiceSessionBloc, AiVoiceSessionState>(
        // A failure is transient: it belongs in a snackbar, not as a
        // permanent panel the user then has to dismiss.
        listenWhen: (previous, current) =>
            previous.failureKey != current.failureKey &&
            current.failureKey != null,
        listener: (context, state) => showAppErrorSnackbar(
          context: context,
          title: state.failureKey!.tr(),
        ),
        builder: (context, state) => Column(
          children: [
            const _CloseRow(),
            // The hero is centred in the space above the control, which is
            // what keeps it centred across device heights rather than at a
            // fixed offset from the top.
            Expanded(
              child: Center(
                // Scales down rather than overflowing when a semantic card
                // takes the lower half of the screen. The hero, the status
                // line and the waveform slot have a fixed intrinsic height
                // between them, and on a short device a tall card leaves less
                // than that — which used to be a 62-pixel overflow stripe
                // across the screen.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AiVoiceHero(status: state.status),
                      SizedBox(height: AppSpacing.xxxl),
                      _StatusLabel(status: state.status),
                      // Figma shows the trace only while listening — it is the
                      // user's own voice, so there is nothing to draw when the
                      // microphone is not the subject.
                      SizedBox(height: AppSpacing.md),
                      SizedBox(
                        height: AiVoiceWaveform.reservedHeight,
                        child: state.status == AiVoiceSessionStatus.listening
                            ? const AiVoiceWaveform()
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // The assistant's question, when it is one a card answers. Drawn
            // above the control so the control stays where the user last
            // looked, and selected on the document alone so an audio tick
            // cannot rebuild it — see `AiVoiceInteractionPanel`.
            const AiVoiceInteractionPanel(),
            SizedBox(height: AppSpacing.xl),
            if (state.canOpenSettings) ...[
              // A permanent affordance rather than a snackbar action: a
              // settings redirect that vanishes after four seconds is one the
              // user cannot go back to.
              _SettingsLink(
                onTap: () => context.read<AiVoiceSessionBloc>().add(
                  const AiVoiceSessionSettingsRequested(),
                ),
              ),
              SizedBox(height: AppSpacing.lg),
            ],
            _PrimaryControl(status: state.status),
            SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      );
}

/// Close (X) in the top safe area — Figma `7880:16685`, 32dp at 20/12.
///
/// Ends the session through the bloc's existing end event, which is what
/// releases the microphone, the audio session and the mock's temp takes. The
/// route pop is left to the screen that owns navigation.
class _CloseRow extends StatelessWidget {
  const _CloseRow();

  static const _glyphSize = 32.0;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsetsDirectional.symmetric(
      horizontal: AppSpacing.xl,
      vertical: AppSpacing.md,
    ),
    child: Row(
      children: [
        Semantics(
          button: true,
          label: 'ai_chat.voice_end'.tr(),
          child: InkWell(
            onTap: () => context.read<AiVoiceSessionBloc>().add(
              const AiVoiceSessionEndRequested(),
            ),
            customBorder: const CircleBorder(),
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xs),
              child: SvgPicture.asset(
                AppSvgs.aiChatVoiceClose,
                package: AppAssets.package,
                width: _glyphSize,
                height: _glyphSize,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// The state line — Figma: Inter Medium 20, white, centred.
class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.status});

  final AiVoiceSessionStatus status;

  @override
  Widget build(BuildContext context) {
    final key = switch (status) {
      AiVoiceSessionStatus.idle => 'ai_chat.voice_idle',
      AiVoiceSessionStatus.connecting => 'ai_chat.voice_connecting',
      AiVoiceSessionStatus.listening => 'ai_chat.voice_listening',
      AiVoiceSessionStatus.processing => 'ai_chat.voice_processing',
      AiVoiceSessionStatus.speaking => 'ai_chat.voice_speaking',
      AiVoiceSessionStatus.awaitingInteraction =>
        'ai_chat.voice_awaiting_interaction',
      AiVoiceSessionStatus.ending => 'ai_chat.voice_ending',
      AiVoiceSessionStatus.ended => 'ai_chat.voice_ended',
      AiVoiceSessionStatus.error => 'ai_chat.voice_error',
    };

    return Semantics(
      liveRegion: true,
      child: Text(
        key.tr(),
        textAlign: TextAlign.center,
        style: context.appTypography.largeNormal.copyWith(
          color: context.appColors.textInverse,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// What a tap on the single control means right now, derived purely from the
/// session status.
///
/// Keeping this as a pure mapping is what lets the button hold no state: the
/// widget asks the status what to draw and what to dispatch, so the two can
/// never disagree, and adding a status forces a decision here rather than
/// silently falling through.
enum _VoiceAction {
  /// Nothing is running — begin the session.
  start,

  /// The user is talking — hand the turn over.
  finishTurn,

  /// The assistant is talking — cut in.
  interrupt,

  /// Connecting, thinking, or tearing down: the control waits.
  busy
  ;

  static _VoiceAction of(AiVoiceSessionStatus status) => switch (status) {
    AiVoiceSessionStatus.idle ||
    AiVoiceSessionStatus.ended ||
    AiVoiceSessionStatus.error => _VoiceAction.start,
    AiVoiceSessionStatus.listening => _VoiceAction.finishTurn,
    AiVoiceSessionStatus.speaking => _VoiceAction.interrupt,
    AiVoiceSessionStatus.connecting ||
    AiVoiceSessionStatus.processing ||
    // The card is the affordance while one is up. A live button here would
    // offer a second way to advance the turn, and the two would disagree
    // about what the user meant.
    AiVoiceSessionStatus.awaitingInteraction ||
    AiVoiceSessionStatus.ending => _VoiceAction.busy,
  };

  AiVoiceSessionEvent? get event => switch (this) {
    _VoiceAction.start => const AiVoiceSessionStartRequested(),
    _VoiceAction.finishTurn => const AiVoiceSessionTurnFinished(),
    _VoiceAction.interrupt => const AiVoiceSessionInterrupted(),
    _VoiceAction.busy => null,
  };

  /// A microphone invites the user to speak; a square says "I am capturing —
  /// tap to stop", which is the same promise in both the listening and the
  /// speaking states.
  bool get showsStopGlyph =>
      this == _VoiceAction.finishTurn || this == _VoiceAction.interrupt;

  String get semanticKey => switch (this) {
    _VoiceAction.start => 'ai_chat.voice_start',
    _VoiceAction.finishTurn => 'ai_chat.voice_finish_turn',
    _VoiceAction.interrupt => 'ai_chat.voice_interrupt',
    _VoiceAction.busy => 'ai_chat.voice_processing',
  };
}

/// The one control — Figma `7880:16722`: 64dp, 10% white, fully rounded.
class _PrimaryControl extends StatelessWidget {
  const _PrimaryControl({required this.status});

  static const _size = 64.0;
  static const _micSize = 26.0;
  static const _stopSize = 16.59;
  static const _stopRadius = 2.0;

  /// Figma `rgba(245,245,245,0.1)`.
  static const _fill = Color(0x1AF5F5F5);

  final AiVoiceSessionStatus status;

  @override
  Widget build(BuildContext context) {
    final action = _VoiceAction.of(status);
    final event = action.event;
    final onSurface = context.appColors.textInverse;

    return Semantics(
      button: true,
      enabled: event != null,
      label: action.semanticKey.tr(),
      child: Material(
        color: _fill,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          // Disabled rather than hidden while the session is busy, so the
          // control never moves under the user's finger mid-conversation.
          onTap: event == null
              ? null
              : () => context.read<AiVoiceSessionBloc>().add(event),
          child: SizedBox.square(
            dimension: _size,
            child: Center(
              child: action.showsStopGlyph
                  ? Container(
                      width: _stopSize,
                      height: _stopSize,
                      decoration: BoxDecoration(
                        color: onSurface,
                        borderRadius: BorderRadius.circular(_stopRadius),
                      ),
                    )
                  : SvgPicture.asset(
                      AppSvgs.aiChatComposerMic,
                      package: AppAssets.package,
                      width: _micSize,
                      height: _micSize,
                      // The composer's mic is a dark glyph for a white card;
                      // on this ground it has to invert.
                      colorFilter: ColorFilter.mode(
                        onSurface,
                        BlendMode.srcIn,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Offers the system settings path after a permanent microphone refusal.
class _SettingsLink extends StatelessWidget {
  const _SettingsLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onTap,
    child: Text(
      'common.open_settings'.tr(),
      style: context.appTypography.regularNormal.copyWith(
        color: context.appColors.textInverse,
        decoration: TextDecoration.underline,
        decorationColor: context.appColors.textInverse,
      ),
    ),
  );
}
