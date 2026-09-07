import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/ai_voice_session_bloc.dart';

/// The Live Voice listening waveform — Figma `7880:16701`.
///
/// Eighteen lime bars whose heights come from the **real microphone**, not
/// from an animation. Figma animates each bar on its own offset scale track;
/// here the same silhouette is produced by the level history, so what the user
/// sees is their own voice. Requirement: no fabricated microphone activity.
///
/// ## Why this listens rather than rebuilds
///
/// `VoiceLevelController` ticks many times a second. It is a `ValueListenable`
/// deliberately kept **out** of Bloc state, so this widget subscribes to it
/// directly and only the painter repaints — the label, the hero and the button
/// above it never rebuild for a microphone frame. A `RepaintBoundary` keeps
/// those repaints off the rest of the screen.
class AiVoiceWaveform extends StatelessWidget {
  /// Creates the waveform.
  const AiVoiceWaveform({super.key});

  /// Figma's bar geometry (`7880:16703`‥`16721`): 3dp wide, 2dp apart, over a
  /// ~29dp tall band.
  static const _barWidth = 3.0;
  static const _barGap = 2.0;
  static const _maxHeight = 29.25;

  /// Each bar's **resting** height, in Figma's own left-to-right order, and
  /// the reason silence still reads as a waveform.
  ///
  /// Figma gives every bar a fixed height and then animates its *scale*; the
  /// shape is design, the movement is data. Driving height straight from the
  /// level instead collapsed every bar to the same 3dp at rest, which drew a
  /// row of dots rather than the trace Figma shows. So the silhouette below is
  /// the design's, and the microphone only scales it — no invented activity,
  /// and an idle microphone looks like Figma's idle state.
  static const _restingHeights = <double>[
    6.75, 15.75, 11.25, 24.75, 14.25, 18.75, 29.25, 15, 9.75, //
    6.75, 15.75, 11.25, 24.75, 14.25, 18.75, 29.25, 15, 9.75,
  ];

  /// How much of a bar's resting height shows with no input, and how far a
  /// full-scale level can push it.
  static const _restScale = 0.42;
  static const _liveScale = 1.35;

  static const int _barCount = 18;

  /// The band the page reserves for this row, so the layout does not shift
  /// when the trace appears and disappears between states.
  static const double reservedHeight = _maxHeight;

  /// Figma's lime.
  static const Color _barColor = Color(0xFF87FC00);

  @override
  Widget build(BuildContext context) {
    final level = context.read<AiVoiceSessionBloc>().level;

    return RepaintBoundary(
      child: SizedBox(
        height: _maxHeight,
        width: _barCount * _barWidth + (_barCount - 1) * _barGap,
        child: ValueListenableBuilder<double>(
          valueListenable: level,
          // The history, not the single value: one number can only make every
          // bar the same height. The series is what gives the trace its shape.
          builder: (context, _, _) => CustomPaint(
            painter: _WaveformPainter(
              levels: level.history,
              color: _barColor,
              barWidth: _barWidth,
              barGap: _barGap,
              restingHeights: _restingHeights,
              restScale: _restScale,
              liveScale: _liveScale,
            ),
          ),
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  const _WaveformPainter({
    required this.levels,
    required this.color,
    required this.barWidth,
    required this.barGap,
    required this.restingHeights,
    required this.restScale,
    required this.liveScale,
  });

  final List<double> levels;
  final Color color;
  final double barWidth;
  final double barGap;
  final List<double> restingHeights;
  final double restScale;
  final double liveScale;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final paint = Paint()..color = color;
    final count = restingHeights.length;
    final radius = Radius.circular(barWidth / 2);

    for (var i = 0; i < count; i++) {
      // Newest on the right: walk the history backwards from its end so the
      // trace scrolls the way the eye expects, and fall back to silence when
      // the history is still filling.
      final index = levels.length - count + i;
      final level = index >= 0 && index < levels.length ? levels[index] : 0.0;
      // Figma's silhouette, scaled by what the microphone actually heard.
      final scale = restScale + (liveScale - restScale) * level.clamp(0.0, 1.0);
      final height = (restingHeights[i] * scale).clamp(
        barWidth,
        size.height,
      );
      final left = i * (barWidth + barGap);
      final top = (size.height - height) / 2;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, barWidth, height),
          radius,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) =>
      !identical(oldDelegate.levels, levels) || oldDelegate.color != color;
}
