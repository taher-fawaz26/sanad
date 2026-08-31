import 'package:design_system/design_system.dart';
import 'package:device/device.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The barrier shown while the app lock is engaged.
///
/// Rendered *instead of* the router, not over it, so no protected widget is
/// built while the gate is shut.
class AppLockScreen extends StatelessWidget {
  const AppLockScreen({
    required this.onUnlock,
    required this.onLogout,
    super.key,
    this.busy = false,
    this.lastFailure,
  });

  /// Raises the OS prompt again. Only ever user-initiated from here — the gate
  /// never auto-retries after a failure, which is what prevents a prompt loop.
  final VoidCallback onUnlock;

  /// Escape hatch. Without this, a user who cannot pass the gate — a broken
  /// sensor, a forgotten passcode — would have no way out of the app short of
  /// reinstalling it.
  final VoidCallback onLogout;

  /// An OS prompt is currently on screen.
  final bool busy;

  final BiometricAuthStatus? lastFailure;

  /// Copy for the previous attempt.
  ///
  /// `local_auth` cannot distinguish a cancelled prompt from a failed match,
  /// so this deliberately never claims which happened.
  String? get _failureMessage => switch (lastFailure) {
    null || BiometricAuthStatus.success => null,
    BiometricAuthStatus.lockedOut => 'settings.biometric_error_locked_out'.tr(),
    BiometricAuthStatus.notAvailable ||
    BiometricAuthStatus.notEnrolled ||
    BiometricAuthStatus.passcodeNotSet =>
      'settings.biometric_error_not_available'.tr(),
    _ => 'settings.biometric_error_generic'.tr(),
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final message = _failureMessage;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        // Scrollable rather than a bare centred Column: this screen has no
        // app bar to escape from, so on a short device — or at the largest
        // accessibility text scale — an unscrollable column would clip the
        // Unlock and Log out buttons and strand the user behind the gate.
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 48, color: colors.gray400),
                  SizedBox(height: AppSpacing.lg),
                  Text(
                    'settings.app_lock_screen_title'.tr(),
                    textAlign: TextAlign.center,
                    style: typography.titleMedium,
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'settings.app_lock_screen_subtitle'.tr(),
                    textAlign: TextAlign.center,
                    style: typography.regularNormal.copyWith(
                      color: colors.gray400,
                    ),
                  ),
                  if (message != null) ...[
                    SizedBox(height: AppSpacing.md),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: typography.regularNormal.copyWith(
                        color: colors.error,
                      ),
                    ),
                  ],
                  SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label: 'settings.app_lock_screen_unlock'.tr(),
                    isLoading: busy,
                    onPressed: busy ? null : onUnlock,
                  ),
                  SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: 'settings.logout'.tr(),
                    variant: AppButtonVariant.secondary,
                    onPressed: onLogout,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
