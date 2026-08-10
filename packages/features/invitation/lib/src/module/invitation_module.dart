import 'package:core/core.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:invitation/src/di/invitation_di.dart';
import 'package:invitation/src/presentation/pages/invitation_details_page.dart';
import 'package:invitation/src/presentation/pages/invitation_otp_page.dart';
import 'package:invitation/src/presentation/pages/invitation_success_page.dart';
import 'package:invitation/src/routes/invitation_routes.dart';
import 'package:invitation/src/routing/invitation_route_args.dart';

/// Worker-invitation acceptance flow (Invitation Details → OTP → Success).
///
/// Backed by the real `workers/verify-token` / `workers/invitations/*`
/// endpoints (see `InvitationRepository`). What's still missing is the
/// OS-level deep link that's supposed to land an invitee on
/// [InvitationRoutes.details] with a real token in the first place —
/// neither `apps/sanad_provider` nor `apps/sanad_client` register a URL
/// scheme / associated domain, or use `app_links`/`uni_links`, or otherwise
/// parse an initial deep link anywhere in the router setup. That's a
/// separate, larger cross-cutting task (Android intent-filter, iOS
/// associated domains, GoRouter wiring in both apps) — out of scope here.
/// Until it lands, [InvitationRoutes.detailsPath] is the only way to reach
/// this flow, and nothing in either app currently calls it.
class InvitationModule extends FeatureModule {
  @override
  String get name => 'invitation';

  @override
  String get version => '0.2.0';

  @override
  List<String> get dependencies => const [];

  @override
  void registerDependencies() => InvitationDI.init();

  @override
  List<RouteBase> routes(FeatureRouteContext context) => [
    GoRoute(
      path: InvitationRoutes.details,
      builder: (context, state) => InvitationDetailsPage(
        token: state.pathParameters['token'] ?? '',
      ),
    ),
    GoRoute(
      path: InvitationRoutes.otp,
      builder: (context, state) {
        final args = state.extra;
        // Reached without the token/preview carried from the details page
        // (e.g. a deep link straight to `/invitation/otp`, or a stale
        // back-stack entry) — nothing useful to verify against, so bounce
        // back rather than crash on a bad cast.
        if (args is! InvitationOtpRouteArgs) {
          return const _InvitationRouteArgsMissing();
        }
        return InvitationOtpPage(args: args);
      },
    ),
    GoRoute(
      path: InvitationRoutes.success,
      builder: (context, state) {
        final args = state.extra;
        if (args is! InvitationSuccessRouteArgs) {
          return const _InvitationRouteArgsMissing();
        }
        return InvitationSuccessPage(args: args);
      },
    ),
  ];
}

/// Rendered instead of crashing when a route is reached without its
/// required `extra` payload. Pops immediately post-frame — there's nothing
/// else safe to show without the missing token/session.
class _InvitationRouteArgsMissing extends StatefulWidget {
  const _InvitationRouteArgsMissing();

  @override
  State<_InvitationRouteArgsMissing> createState() =>
      _InvitationRouteArgsMissingState();
}

class _InvitationRouteArgsMissingState
    extends State<_InvitationRouteArgsMissing> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
