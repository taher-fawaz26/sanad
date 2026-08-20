import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_ui/src/states/app_empty_state.dart';

/// Full-screen page shown when the signed-in user lacks permission for the
/// route/action they reached (403).
///
/// Route-agnostic — takes an [onGoHome] callback rather than a home path so
/// design_system stays free of app-level route knowledge. Mirrors
/// [AppNotFoundPage]'s structure; only the illustration and copy differ.
class AppForbiddenPage extends StatelessWidget {
  const AppForbiddenPage({
    required this.title,
    required this.description,
    required this.homeLabel,
    required this.onGoHome,
    super.key,
  });

  /// Localized heading (e.g. "Access Denied").
  final String title;

  /// Localized supporting text.
  final String description;

  /// Localized label for the primary CTA (e.g. "Back to Dashboard").
  final String homeLabel;

  /// Callback invoked when the user taps the primary CTA.
  final VoidCallback onGoHome;

  @override
  Widget build(BuildContext context) {
    final size = responsiveDimension(EmptyStateTokens.emptyIllustrationWidth);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppEmptyState(
                  illustration: Semantics(
                    excludeSemantics: true,
                    child: Lottie.asset(
                      AppAnimations.forbidden403,
                      package: AppAssets.package,
                      width: size,
                      height: size,
                      fit: BoxFit.contain,
                      repeat: true,
                    ),
                  ),
                  title: title,
                  description: description,
                ),
                const SizedBox(height: 24),
                AppButton(label: homeLabel, onPressed: onGoHome),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
