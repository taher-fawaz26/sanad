import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:registration/src/presentation/cubit/registration_cubit.dart';
import 'package:registration/src/presentation/pages/capture_preview_front_page.dart';
import 'package:registration/src/presentation/pages/identity_verification_page.dart';
import 'package:registration/src/presentation/pages/organization_details_page.dart';
import 'package:registration/src/presentation/pages/scan_emirates_id_front_page.dart';
import 'package:registration/src/presentation/pages/select_account_type_page.dart';
import 'package:registration/src/presentation/pages/sign_up_email_page.dart';
import 'package:registration/src/presentation/pages/sign_up_otp_page.dart';
import 'package:registration/src/routes/registration_routes.dart';

/// Wires up the sign-up flow.
///
/// A [ShellRoute] wraps all sub-routes so a single [RegistrationCubit]
/// is created once when the user enters `/signup` and disposed automatically
/// when they leave the entire flow.
class RegistrationModule extends FeatureModule {
  @override
  String get name => 'registration';

  @override
  String get version => '0.1.0';

  @override
  List<String> get dependencies => const [];

  @override
  void registerDependencies() {}

  static const Set<String> _authShellSteps = {
    RegistrationRoutes.signUpEmail,
    RegistrationRoutes.signUpOtp,
    RegistrationRoutes.selectAccountType,
    RegistrationRoutes.organizationDetails,
    RegistrationRoutes.identityVerification,
  };

  static const Set<String> _stepsWithBack = {
    RegistrationRoutes.organizationDetails,
    RegistrationRoutes.identityVerification,
  };

  @override
  List<RouteBase> routes(FeatureRouteContext context) => [
    ShellRoute(
      builder: (context, state, child) {
        final path = state.matchedLocation;
        final useAuthShell = _authShellSteps.contains(path);
        final showBack = _stepsWithBack.contains(path);

        return BlocProvider(
          create: (_) => RegistrationCubit(),
          child: useAuthShell
              ? AuthScreenShell(
                  onBack: showBack ? () => context.pop() : null,
                  child: child,
                )
              : child,
        );
      },
      routes: [
        GoRoute(
          path: RegistrationRoutes.signUpEmail,
          builder: (context, state) => const SignUpEmailPage(),
        ),
        GoRoute(
          path: RegistrationRoutes.signUpOtp,
          builder: (context, state) => const SignUpOtpPage(),
        ),
        GoRoute(
          path: RegistrationRoutes.selectAccountType,
          builder: (context, state) => const SelectAccountTypePage(),
        ),
        GoRoute(
          path: RegistrationRoutes.organizationDetails,
          builder: (context, state) => const OrganizationDetailsPage(),
        ),
        GoRoute(
          path: RegistrationRoutes.identityVerification,
          builder: (context, state) => const IdentityVerificationPage(),
        ),
        GoRoute(
          path: RegistrationRoutes.scanEmiratesIdFront,
          builder: (context, state) => const ScanEmiratesIdFrontPage(),
        ),
        GoRoute(
          path: RegistrationRoutes.capturePreviewFront,
          builder: (context, state) => const CapturePreviewFrontPage(),
        ),
      ],
    ),
  ];
}
