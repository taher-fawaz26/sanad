import 'package:app_animations/app_animations.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

enum _DemoStatus { loading, success, error }

/// Widgetbook demo for [AppStateTransition] — tap to cycle through
/// loading → success → error, cross-fading between them.
class MotionStateTransitionDemo extends StatefulWidget {
  /// Creates the demo widget.
  const MotionStateTransitionDemo({super.key});

  @override
  State<MotionStateTransitionDemo> createState() =>
      _MotionStateTransitionDemoState();
}

class _MotionStateTransitionDemoState extends State<MotionStateTransitionDemo> {
  _DemoStatus _status = _DemoStatus.loading;

  void _advance() {
    setState(() {
      final next = (_status.index + 1) % _DemoStatus.values.length;
      _status = _DemoStatus.values[next];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 40,
          child: AppStateTransition<_DemoStatus>(
            value: _status,
            builder: (context, status) => switch (status) {
              _DemoStatus.loading => const AppLoadingIndicator(size: 32),
              _DemoStatus.success => Icon(
                Icons.check_circle,
                color: context.appColors.success500,
                size: 32,
              ),
              _DemoStatus.error => Icon(
                Icons.error,
                color: context.appColors.error500,
                size: 32,
              ),
            },
          ),
        ),
        SizedBox(height: AppSpacing.md),
        AppButton(label: 'Advance', onPressed: _advance),
      ],
    );
  }
}
