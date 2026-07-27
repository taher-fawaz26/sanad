import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forgot_password/src/presentation/models/create_new_password_args.dart';
import 'package:forgot_password/src/presentation/bloc/forgot_password_bloc.dart';
import 'package:forgot_password/src/presentation/pages/forgot_password_otp_page.dart';
import 'package:forgot_password/src/routes/forgot_password_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:otp/otp.dart';

/// Router helpers shared by every app that hosts the auth + otp +
/// forgot-password flows.
///
/// Both `sanad_client` and `sanad_provider` used to inline the same
/// `MultiBlocProvider` + combined-OTP `GoRoute` (~40 lines each). Any drift
/// between them broke the shared flow silently. Consolidated here so the
/// shell is defined once.
///
/// `forgot_password` already sits at the top of the auth-adjacent tier
/// (depends on `auth` + `otp`), which makes it the natural aggregator —
/// neither `auth` nor `otp` alone can express this shell without leaking a
/// sibling dependency.
abstract final class AuthShell {
  AuthShell._();

  /// Wraps [children] in a shell that provides `AuthBloc`, `OtpBloc`, and
  /// `ForgotPasswordBloc` to every descendant route.
  static ShellRoute buildShellRoute({required List<RouteBase> children}) =>
      ShellRoute(
        builder: (context, state, child) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => sl<AuthBloc>()),
            BlocProvider(create: (_) => sl<OtpBloc>()),
            BlocProvider(create: (_) => sl<ForgotPasswordBloc>()),
          ],
          child: child,
        ),
        routes: children,
      );

  /// Combined OTP route — same behavior for verification and
  /// forgot-password flows, keyed off `OtpArgs.flow`.
  static GoRoute combinedOtpRoute() => GoRoute(
    path: OtpRoutes.otp,
    redirect: (context, state) =>
        state.extra is OtpArgs ? null : AuthRoutes.login,
    builder: (context, state) {
      final args = state.extra! as OtpArgs;
      if (args.flow == OtpFlow.forgotPassword) {
        return ForgotPasswordOtpPage(
          args: args,
          onBackToLogin: () => context.go(AuthRoutes.login),
          onVerified: (identifier) {
            context.push(
              ForgotPasswordRoutes.resetPassword,
              extra: CreateNewPasswordArgs(identifier: identifier),
            );
          },
        );
      }
      return VerificationCodePage(
        args: args,
        onVerified: () => context.go(AuthRoutes.login),
        onBackToLogin: () => context.go(AuthRoutes.login),
      );
    },
  );
}
