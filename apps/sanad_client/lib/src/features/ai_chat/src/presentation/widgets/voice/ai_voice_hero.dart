import 'dart:math' as math;

import 'package:app_animations/app_animations.dart';
import 'package:app_assets/app_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/enums/ai_voice_session_status.dart';

/// The Live Voice hero — Figma `7880:16689`: a 200dp box holding the green
/// bloom with Sanad's mark riding on it.
///
/// ## Why this is not a Lottie
///
/// It should be, and the wiring for one already exists (`AppLottie`). The
/// authored export registered at `AppAnimations.aiAssistantLoading` still
/// draws entirely through image layers whose PNGs are not in this package —
/// its own doc comment records this — so it paints an empty box. No corrected
/// export or `/i/` image package has arrived, so nothing here was replaced by
/// a placeholder: the mark is Figma's exact exported asset and the motion is
/// Figma's own published keyframe track. Dropping a real Lottie in later
/// replaces this one widget.
///
/// ## Motion
///
/// Transcribed from Figma's 4.2s timeline cohort for this node, not invented:
///
/// - the bloom (`7880:16689`) breathes opacity `0.5 → 1 → 0.5` and scale
///   `0.92 → 1.08 → 0.92`, peaking at 17.86% and resting from 35.7%
/// - the mark (`7880:16695`) turns a half rotation over the first 71.4% and
///   counter-breathes `0.95 → 1.05 → 0.95`
///
/// ## State
///
/// Figma draws the same hero in every voice state, so the animation does not
/// change shape per status — it only **stills** when the session is not
/// active, which is the one distinction the design makes between a live
/// conversation and an idle screen. That is presentation-only: no status is
/// invented and none is consumed beyond `isActive`.
class AiVoiceHero extends StatefulWidget {
  /// Creates the hero for [status].
  const AiVoiceHero({required this.status, super.key});

  /// Drives only whether the motion runs.
  final AiVoiceSessionStatus status;

  @override
  State<AiVoiceHero> createState() => _AiVoiceHeroState();
}

class _AiVoiceHeroState extends State<AiVoiceHero>
    with SingleTickerProviderStateMixin {
  /// Figma's timeline cohort length for this node.
  static const _period = Duration(milliseconds: 4200);

  /// Figma's 200dp hero frame, with the mark at ~86×84 inside it.
  static const _frameSize = 200.0;
  static const _markWidth = 85.95;
  static const _markHeight = 84.16;

  /// The bloom is drawn past the frame so its falloff completes before the
  /// edge instead of clipping into a visible disc.
  static const _bloomSize = 260.0;

  /// Figma's bloom green and the lime it fades toward.
  static const _bloomCore = Color(0xFF5CE01E);
  static const _bloomMid = Color(0xFF2E8B3A);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _period,
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(AiVoiceHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status.isActive != widget.status.isActive) _sync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  /// Runs the loop only while the session is live and motion is allowed.
  void _sync() {
    final shouldRun =
        widget.status.isActive && !AppMotion.reduceMotionOf(context);
    if (shouldRun && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!shouldRun && _controller.isAnimating) {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Figma's shared breathe envelope: rise to the peak at 17.857%, fall back
  /// by 35.714%, then hold. Returned as 0..1 so each layer can scale it to its
  /// own range.
  double _envelope(double t) {
    const peak = 0.17857;
    const rest = 0.35714;
    if (t <= peak) return Curves.easeInOut.transform(t / peak);
    if (t <= rest) {
      return 1 - Curves.easeInOut.transform((t - peak) / (rest - peak));
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: SizedBox.square(
      dimension: _frameSize,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final e = _envelope(t);

          // Bloom: opacity 0.5→1, scale 0.92→1.08.
          final bloomOpacity = 0.5 + 0.5 * e;
          final bloomScale = 0.92 + 0.16 * e;
          // Mark: half turn over the first 71.4%, then held.
          final turn = (t / 0.71429).clamp(0.0, 1.0);
          final markScale = 0.95 + 0.10 * e;

          return Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: bloomOpacity,
                child: Transform.scale(
                  scale: bloomScale,
                  child: const _Bloom(size: _bloomSize),
                ),
              ),
              Transform.rotate(
                angle: turn * math.pi,
                child: Transform.scale(
                  scale: markScale,
                  child: SvgPicture.asset(
                    AppSvgs.aiChatVoiceMark,
                    package: AppAssets.package,
                    width: _markWidth,
                    height: _markHeight,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

/// The radial bloom behind the mark. Figma builds it from two large blurred
/// shapes; a radial gradient is the same result with far less to composite.
class _Bloom extends StatelessWidget {
  const _Bloom({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: const DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            _AiVoiceHeroState._bloomCore,
            _AiVoiceHeroState._bloomMid,
            Color(0x0010412F),
          ],
          stops: [0, 0.42, 1],
        ),
      ),
    ),
  );
}
