import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui/src/states/app_empty_state.dart';

/// Full-screen page shown when GoRouter can't match a URL.
///
/// Route-agnostic — takes an [onGoHome] callback rather than a home path so
/// design_system stays free of app-level route knowledge.
class AppNotFoundPage extends StatelessWidget {
  const AppNotFoundPage({
    required this.title,
    required this.description,
    required this.homeLabel,
    required this.onGoHome,
    super.key,
  });

  /// Localized heading (e.g. "Page not found").
  final String title;

  /// Localized supporting text.
  final String description;

  /// Localized label for the primary CTA (e.g. "Go home").
  final String homeLabel;

  /// Callback invoked when the user taps the primary CTA.
  final VoidCallback onGoHome;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppGenericEmptyState(
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
