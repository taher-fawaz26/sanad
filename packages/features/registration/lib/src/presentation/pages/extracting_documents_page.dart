import 'dart:math' as math;

import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:registration/src/presentation/cubit/registration_cubit.dart';
import 'package:registration/src/presentation/cubit/registration_state.dart';
import 'package:registration/src/presentation/widgets/registration_scan_chrome.dart';
import 'package:registration/src/routes/registration_routes.dart';

const _kOrbSize = 180.0;

/// Step 8 — "AI extracting document information" loading step.
///
/// Figma: `AI` (`3125:24217`). Runs the (simulated) extraction on entry and
/// replaces itself with the Review Information screen when it completes.
class ExtractingDocumentsPage extends HookWidget {
  const ExtractingDocumentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final animation = useAnimationController(
      duration: const Duration(seconds: 3),
    )..repeat();

    useEffect(() {
      context.read<RegistrationCubit>().extractDocuments();
      return null;
    }, const []);

    return BlocListener<RegistrationCubit, RegistrationState>(
      listenWhen: (prev, curr) =>
          prev.extractionStatus != curr.extractionStatus,
      listener: (context, state) {
        if (state.extractionStatus == ExtractionStatus.done) {
          context.pushReplacement(RegistrationRoutes.reviewInformation);
        }
      },
      child: RegistrationGradientScaffold(
        child: Column(
          children: [
            SizedBox(height: responsiveDimension(AppSpacing.xxxxl)),
            AppSvgPicture.asset(
              AppSvgs.sanadLogo,
              width: responsiveDimension(160),
              height: responsiveDimension(52),
            ),
            const Spacer(),
            _ExtractingOrb(animation: animation, color: colors.primary300),
            const Spacer(),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsiveDimension(AppSpacing.xl),
              ),
              child: Text(
                'registration.extracting'.tr(),
                textAlign: TextAlign.center,
                style: typography.regularNormal.copyWith(
                  color: colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: responsiveDimension(AppSpacing.xxxxl)),
          ],
        ),
      ),
    );
  }
}

/// A softly pulsing, rotating orb approximating the Figma glass sphere.
class _ExtractingOrb extends StatelessWidget {
  const _ExtractingOrb({required this.animation, required this.color});

  final Animation<double> animation;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final size = responsiveDimension(_kOrbSize);
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final pulse = 0.92 + 0.08 * math.sin(animation.value * 2 * math.pi);
        return Transform.scale(
          scale: pulse,
          child: Transform.rotate(
            angle: animation.value * 2 * math.pi,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    color.withValues(alpha: 0.15),
                    color.withValues(alpha: 0.75),
                    Colors.white.withValues(alpha: 0.9),
                    color.withValues(alpha: 0.15),
                  ],
                  stops: const [0.0, 0.45, 0.6, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 40,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: size * 0.6,
                  height: size * 0.6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.35),
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.25),
                        Colors.black.withValues(alpha: 0.35),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
