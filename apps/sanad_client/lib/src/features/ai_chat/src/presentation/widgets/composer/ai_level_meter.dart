import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// A bar meter that follows a live audio level.
///
/// A `CustomPainter` over a handful of doubles rather than a waveform package:
/// the whole thing is one `drawRRect` per bar, and a dependency for that would
/// be more to audit and upgrade than the code it replaces.
///
/// ## Why it takes a series and not a number
///
/// It used to take a single `level` and scale a fixed symmetric profile by it,
/// which meant every bar moved together: the meter could only be a blob that
/// grew and shrank, and at silence every bar sat on the minimum height and it
/// read as a flat dotted line. A voice rising and falling is a *series*, so
/// this draws one — [levels], oldest at the start, scrolling as the microphone
/// ticks. Nothing here is synthesised; every bar is a reading.
///
/// It repaints on the series alone, and sits under a `RepaintBoundary`, so a
/// tick never touches the layout around it.
class AiLevelMeter extends StatelessWidget {
  /// Creates a meter driven by [levels].
  const AiLevelMeter({
    required this.levels,
    super.key,
    this.height = 32,
    this.color,
  });

  /// Recent loudness readings, 0..1, oldest first.
  final List<double> levels;

  /// Meter height.
  final double height;

  /// Bar colour; defaults to the theme's primary.
  final Color? color;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      size: Size.infinite,
      painter: _LevelMeterPainter(
        levels: levels,
        color: color ?? context.appColors.primary,
      ),
      child: SizedBox(height: height, width: double.infinity),
    ),
  );
}

class _LevelMeterPainter extends CustomPainter {
  const _LevelMeterPainter({required this.levels, required this.color});

  final List<double> levels;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (levels.isEmpty || size.width <= 0 || size.height <= 0) return;

    final slot = size.width / levels.length;
    final barWidth = (slot * 0.5).clamp(1.0, slot);
    final centre = size.height / 2;
    final paint = Paint()..color = color;

    for (var i = 0; i < levels.length; i++) {
      // A floor so the meter reads as "listening" rather than "broken" during
      // a pause, and a minimum that is visibly a bar rather than a dot.
      final barHeight = (size.height * levels[i]).clamp(3.0, size.height);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            i * slot + (slot - barWidth) / 2,
            centre - barHeight / 2,
            barWidth,
            barHeight,
          ),
          Radius.circular(barWidth / 2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_LevelMeterPainter oldDelegate) =>
      !identical(oldDelegate.levels, levels) || oldDelegate.color != color;
}

/// A static waveform for a finished recording.
///
/// Takes the capped sample list off `AiAudioAttachment`, so drawing a
/// five-minute take costs exactly as much as drawing a five-second one.
class AiStaticWaveform extends StatelessWidget {
  /// Creates a waveform for [samples], highlighting up to [progress].
  const AiStaticWaveform({
    required this.samples,
    super.key,
    this.progress = 0,
    this.height = 24,
  });

  /// Normalised 0..1 amplitudes.
  final List<double> samples;

  /// Playback completion, 0..1. Bars before it are drawn in the active colour.
  final double progress;

  /// Waveform height.
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return RepaintBoundary(
      child: CustomPaint(
        painter: _StaticWaveformPainter(
          samples: samples,
          progress: progress,
          playedColor: colors.primary,
          remainingColor: colors.border,
        ),
        child: SizedBox(height: height, width: double.infinity),
      ),
    );
  }
}

class _StaticWaveformPainter extends CustomPainter {
  const _StaticWaveformPainter({
    required this.samples,
    required this.progress,
    required this.playedColor,
    required this.remainingColor,
  });

  final List<double> samples;
  final double progress;
  final Color playedColor;
  final Color remainingColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty || size.width <= 0) return;

    final slot = size.width / samples.length;
    final barWidth = (slot * 0.6).clamp(1.0, slot);
    final centre = size.height / 2;
    final playedUpTo = samples.length * progress;

    for (var i = 0; i < samples.length; i++) {
      final barHeight = (size.height * samples[i]).clamp(2.0, size.height);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            i * slot + (slot - barWidth) / 2,
            centre - barHeight / 2,
            barWidth,
            barHeight,
          ),
          Radius.circular(barWidth / 2),
        ),
        Paint()..color = i < playedUpTo ? playedColor : remainingColor,
      );
    }
  }

  @override
  bool shouldRepaint(_StaticWaveformPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.samples != samples ||
      oldDelegate.playedColor != playedColor ||
      oldDelegate.remainingColor != remainingColor;
}
