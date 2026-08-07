import 'package:auth/src/presentation/bloc/auth/auth_bloc.dart';
import 'package:auth/src/presentation/pages/email_otp_page.dart';
import 'package:auth/src/routes/auth_routes.dart';
import 'package:core/core.dart' show sl;
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Router helpers shared by every app that hosts the authentication flow.
///
/// Provides a single app-wide [AuthBloc] to every descendant route and exposes
/// the shared passwordless OTP route. Lives in `auth` (the base of the
/// auth tier) so it carries no dependency on any sibling feature package.
abstract final class AuthShell {
  AuthShell._();

  /// Wraps [children] in a shell that provides [AuthBloc] to every descendant.
  static ShellRoute buildShellRoute({required List<RouteBase> children}) =>
      ShellRoute(
        builder: (context, state, child) => BlocProvider(
          create: (_) => sl<AuthBloc>(),
          child: child,
        ),
        routes: children,
      );

  /// The shared OTP route. The email is passed as the route `extra`; navigating
  /// here without one bounces back to login.
  ///
  /// [onAuthenticated] runs for an existing user (session started);
  /// [onOnboarding] runs for a new user that must complete registration.
  static GoRoute otpRoute({
    required void Function(BuildContext context) onAuthenticated,
    required void Function(
      BuildContext context,
      String email,
      String onboardingToken,
    )
    onOnboarding,
  }) => GoRoute(
    path: AuthRoutes.otp,
    redirect: (context, state) =>
        state.extra is String ? null : AuthRoutes.login,
    builder: (context, state) => EmailOtpPage(
      email: state.extra! as String,
      onAuthenticated: () => onAuthenticated(context),
      onOnboarding: (email, token) => onOnboarding(context, email, token),
    ),
  );
}
