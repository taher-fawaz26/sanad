import 'package:account_settings/src/domain/enums/app_lock_capability.dart';
import 'package:account_settings/src/domain/repositories/app_lock_repository.dart';
import 'package:account_settings/src/presentation/bloc/security/security_bloc.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

/// Offers to turn on the app lock, once, after a fresh sign-in.
///
/// Call from an app's post-authentication navigation callback. Deliberately
/// *not* wired to session restoration: the offer belongs to an actual login,
/// not to every cold start that happens to find a session.
///
/// Silent and non-blocking whenever it has nothing to ask — already offered,
/// already on, or a device that cannot authenticate. The user reaches the app
/// either way; the sheet only ever appears on top of it.
Future<void> maybeOfferAppLock(BuildContext context) async {
  final repository = sl<AppLockRepository>();

  if (await repository.hasBeenOffered()) return;
  if (await repository.isEnabled()) return;
  if (await repository.capability() != AppLockCapability.available) return;
  if (!context.mounted) return;

  final accepted = await showConfirmationSheet(
    context: context,
    title: 'settings.app_lock_offer_title'.tr(),
    description: 'settings.app_lock_offer_body'.tr(),
    actionLabel: 'settings.app_lock_offer_enable'.tr(),
    cancelLabel: 'settings.app_lock_offer_not_now'.tr(),
  );

  if (accepted != true) {
    // "Not now" — and a swipe-dismiss is treated the same way. Recorded so the
    // user is not asked again on every subsequent login; Account Settings →
    // Security remains the way in.
    await repository.markOffered();
    return;
  }

  // Accepting routes through SecurityBloc rather than writing the preference
  // here, so the rule that the lock is only ever enabled after a successful
  // local authentication lives in exactly one place.
  final bloc = sl<SecurityBloc>();
  try {
    final settled = bloc.stream.firstWhere(
      (state) =>
          state.toggleStatus == RequestStatus.success ||
          state.toggleStatus == RequestStatus.failure,
    );
    bloc.add(const SecurityAppLockOfferAccepted());
    final result = await settled;

    if (!context.mounted) return;
    if (result.toggleStatus == RequestStatus.success) {
      showAppSnackbar(
        context: context,
        title: 'settings.app_lock_enabled_message'.tr(),
      );
    }
    // A failed or dismissed prompt is left silent: the user just declined or
    // mistyped at the OS sheet, the lock stays off, and the offer has already
    // been recorded so they are not asked again.
  } finally {
    await bloc.close();
  }
}
