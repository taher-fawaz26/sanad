import 'package:auth/auth.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_provider/src/features/registration/src/routes/registration_routes.dart';

/// Back-navigation helpers for the sign-up flow.
///
/// Several steps are reached via [GoRouter.go], so [GoRouter.pop] is not
/// always available. [popStep] falls back to the previous route in the flow.
abstract final class RegistrationNavigation {
  RegistrationNavigation._();

  /// Pops when possible; otherwise navigates to the previous sign-up step.
  static void popStep(BuildContext context, {bool isOrganization = false}) {
    if (context.canPop()) {
      context.pop();
      return;
    }

    final fallback = _fallbackRoute(
      GoRouterState.of(context).uri.path,
      isOrganization,
    );
    if (fallback != null) {
      context.go(fallback);
    }
  }

  static String? _fallbackRoute(String path, bool isOrganization) {
    return switch (path) {
      RegistrationRoutes.selectAccountType => AuthRoutes.login,
      RegistrationRoutes.organizationDetails =>
        RegistrationRoutes.selectAccountType,
      RegistrationRoutes.individualDetails =>
        RegistrationRoutes.selectAccountType,
      RegistrationRoutes.identityVerification =>
        isOrganization
            ? RegistrationRoutes.organizationDetails
            : RegistrationRoutes.individualDetails,
      RegistrationRoutes.tradeLicence =>
        RegistrationRoutes.identityVerification,
      _ => null,
    };
  }
}
