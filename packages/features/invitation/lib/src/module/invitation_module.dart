import 'package:core/core.dart';
import 'package:go_router/go_router.dart';
import 'package:invitation/src/domain/entities/invitation_mock.dart';
import 'package:invitation/src/presentation/pages/invitation_details_page.dart';
import 'package:invitation/src/presentation/pages/invitation_otp_page.dart';
import 'package:invitation/src/presentation/pages/invitation_success_page.dart';
import 'package:invitation/src/routes/invitation_routes.dart';

/// Temporary UI-only invitation flow (Invitation Details → OTP → Success).
///
/// This module exists solely so the flow can be reached and demoed before
/// deep links are wired up. No API, repository, data source, or auth
/// integration is registered here — everything is mocked. Remove the
/// Organization Settings entry point (and, eventually, this module) once
/// real deep-link handling replaces it.
class InvitationModule extends FeatureModule {
  @override
  String get name => 'invitation';

  @override
  String get version => '0.1.0';

  @override
  List<String> get dependencies => const [];

  @override
  void registerDependencies() {}

  @override
  List<RouteBase> routes(FeatureRouteContext context) => [
    GoRoute(
      path: InvitationRoutes.details,
      builder: (context, state) => InvitationDetailsPage(
        invitation: state.extra as InvitationMock? ?? InvitationMock.sample,
      ),
    ),
    GoRoute(
      path: InvitationRoutes.otp,
      builder: (context, state) => InvitationOtpPage(
        invitation: state.extra as InvitationMock? ?? InvitationMock.sample,
      ),
    ),
    GoRoute(
      path: InvitationRoutes.success,
      builder: (context, state) => InvitationSuccessPage(
        invitation: state.extra as InvitationMock? ?? InvitationMock.sample,
      ),
    ),
  ];
}
