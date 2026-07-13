import 'package:design_system/design_system.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/avatar_stack_tokens.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Figma overlapping team avatars with overflow badge (`194:2647`).
class AppAvatarStack extends StatelessWidget {
  const AppAvatarStack({
    required this.avatars,
    super.key,
    this.maxVisible = 4,
    this.overflowCount = 0,
    this.size = AppAvatarSize.small,
  });

  final List<Widget> avatars;
  final int maxVisible;
  final int overflowCount;
  final AppAvatarSize size;

  @override
  Widget build(BuildContext context) {
    final spec = AvatarStackTokens.resolve(
      colors: context.appColors,
      typography: context.appTypography,
    );

    final visible = avatars.take(maxVisible).toList();
    final step = spec.avatarSize - spec.overlap;
    final overflow = overflowCount > 0 ? 1 : 0;
    final width = visible.isEmpty
        ? 0.0
        : spec.avatarSize + (visible.length + overflow - 1) * step;

    return SizedBox(
      width: width,
      height: spec.avatarSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < visible.length; i++)
            Positioned(
              left: i * step,
              child: _BorderedAvatar(
                spec: spec,
                child: SizedBox(
                  width: spec.avatarSize,
                  height: spec.avatarSize,
                  child: visible[i],
                ),
              ),
            ),
          if (overflowCount > 0)
            Positioned(
              left: visible.length * step,
              child: _BorderedAvatar(
                spec: spec,
                child: Container(
                  width: spec.avatarSize,
                  height: spec.avatarSize,
                  decoration: BoxDecoration(
                    color: spec.overflowBackground,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text('+$overflowCount', style: spec.overflowTextStyle),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BorderedAvatar extends StatelessWidget {
  const _BorderedAvatar({required this.spec, required this.child});

  final AvatarStackStyleSpec spec;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: spec.borderColor,
          width: spec.borderWidth,
        ),
      ),
      child: ClipOval(child: child),
    );
  }
}
