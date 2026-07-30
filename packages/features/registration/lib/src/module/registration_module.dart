import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:registration/src/di/registration_di.dart';
import 'package:registration/src/domain/usecases/upload_single_media_usecase.dart';
import 'package:registration/src/presentation/cubit/registration_cubit.dart';
import 'package:registration/src/presentation/models/emirates_id_scan_session.dart';
import 'package:registration/src/presentation/pages/emirates_id_scan_preview_page.dart';
import 'package:registration/src/presentation/pages/extracting_documents_page.dart';
import 'package:registration/src/presentation/pages/identity_verification_page.dart';
import 'package:registration/src/presentation/pages/individual_details_page.dart';
import 'package:registration/src/presentation/pages/organization_details_page.dart';
import 'package:registration/src/presentation/pages/review_id_photos_page.dart';
import 'package:registration/src/presentation/pages/review_information_page.dart';
import 'package:registration/src/presentation/pages/select_account_type_page.dart';
import 'package:registration/src/presentation/pages/sign_up_email_page.dart';
import 'package:registration/src/presentation/pages/trade_licence_page.dart';
import 'package:registration/src/routes/registration_routes.dart';

/// Wires up the sign-up flow.
///
/// A [ShellRoute] wraps all sub-routes so a single [RegistrationCubit] is
/// created once when the user enters `/signup` and disposed automatically when
/// they leave the entire flow. Card steps are wrapped in [AuthScreenShell];
/// the full-screen scan / extraction steps render their own gradient scaffold.
class RegistrationModule extends FeatureModule {
  @override
  String get name => 'registration';

  @override
  String get version => '0.1.0';

  @override
  List<String> get dependencies => const [];

  @override
  void registerDependencies() => RegistrationDI.init();

  /// Steps rendered inside the white [AuthScreenShell] card by this module.
  ///
  /// Document-upload steps ([RegistrationRoutes.identityVerification],
  /// [RegistrationRoutes.tradeLicence]) are intentionally excluded: they wrap
  /// themselves in [AuthScreenShell] so they can pin their action button in the
  /// shell footer (always visible above the scrolling upload cards).
  static const Set<String> _authShellSteps = {
    RegistrationRoutes.signUpEmail,
    RegistrationRoutes.selectAccountType,
    RegistrationRoutes.organizationDetails,
    RegistrationRoutes.individualDetails,
    RegistrationRoutes.reviewInformation,
  };

  /// Card steps that show a back chevron on the gradient header.
  static const Set<String> _stepsWithBack = {
    RegistrationRoutes.selectAccountType,
    RegistrationRoutes.organizationDetails,
    RegistrationRoutes.individualDetails,
  };

  /// Title shown in the collapsed hero bar for each step.
  static const Map<String, String> _stepTitles = {
    RegistrationRoutes.signUpEmail: 'registration.sign_up_title',
    RegistrationRoutes.selectAccountType: 'registration.account_type_title',
    RegistrationRoutes.organizationDetails: 'registration.org_details_title',
    RegistrationRoutes.individualDetails:
        'registration.individual_details_title',
    RegistrationRoutes.reviewInformation: 'registration.review_title',
  };

  @override
  List<RouteBase> routes(FeatureRouteContext routeContext) => [
        ShellRoute(
          builder: (context, state, child) {
            final path = state.uri.path;
            final useAuthShell = _authShellSteps.contains(path);
            final showBack = _stepsWithBack.contains(path);
            final titleKey = _stepTitles[path];

            return BlocProvider(
              create: (_) => RegistrationCubit(
                uploadMedia: sl<UploadSingleMediaUseCase>(),
              ),
              child: useAuthShell
                  ? AuthScreenShell(
                      onBack: showBack ? () => context.pop() : null,
                      title: titleKey?.tr(),
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
              path: RegistrationRoutes.selectAccountType,
              builder: (context, state) => const SelectAccountTypePage(),
            ),
            GoRoute(
              path: RegistrationRoutes.organizationDetails,
              builder: (context, state) => const OrganizationDetailsPage(),
            ),
            GoRoute(
              path: RegistrationRoutes.individualDetails,
              builder: (context, state) => const IndividualDetailsPage(),
            ),
            GoRoute(
              path: RegistrationRoutes.identityVerification,
              builder: (context, state) => const IdentityVerificationPage(),
            ),
            GoRoute(
              path: RegistrationRoutes.reviewIdPhotos,
              builder: (context, state) => const ReviewIdPhotosPage(),
            ),
            GoRoute(
              path: RegistrationRoutes.emiratesIdScanFrontPreview,
              builder: (context, state) => EmiratesIdScanPreviewPage(
                side: EmiratesIdScanSide.front,
                initialSession: state.extra! as EmiratesIdScanSession,
              ),
            ),
            GoRoute(
              path: RegistrationRoutes.emiratesIdScanBackPreview,
              builder: (context, state) => EmiratesIdScanPreviewPage(
                side: EmiratesIdScanSide.back,
                initialSession: state.extra! as EmiratesIdScanSession,
              ),
            ),
            GoRoute(
              path: RegistrationRoutes.tradeLicence,
              builder: (context, state) => const TradeLicencePage(),
            ),
            GoRoute(
              path: RegistrationRoutes.extracting,
              builder: (context, state) => const ExtractingDocumentsPage(),
            ),
            GoRoute(
              path: RegistrationRoutes.reviewInformation,
              builder: (context, state) => ReviewInformationPage(
                homeRoute: routeContext.homeRoute,
              ),
            ),
          ],
        ),
      ];
}
