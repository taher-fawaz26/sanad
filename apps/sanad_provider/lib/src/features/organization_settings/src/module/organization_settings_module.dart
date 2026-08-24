import 'package:core/core.dart';
import 'package:document_flow/document_flow.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_provider/src/features/organization_settings/src/di/organization_settings_di.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/legal_documents/document_scope.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/legal_documents/legal_documents_page.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/legal_documents/organization_document_flow_config.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/pages/general_settings_page.dart';
import 'package:sanad_provider/src/features/organization_settings/src/routes/organization_settings_routes.dart';

/// Provider-only organization settings module.
///
/// The KPI hub at [OrganizationSettingsRoutes.hub] is hosted by the provider
/// shell branch; this module contributes the general-settings placeholder.
class OrganizationSettingsModule extends FeatureModule {
  @override
  String get name => 'organization_settings';

  @override
  String get version => '0.1.0';

  @override
  List<String> get dependencies => const [
    'account_settings',
    'contact_verification',
    'services',
  ];

  @override
  void registerDependencies() => OrganizationSettingsDI.init();

  @override
  List<RouteBase> routes(FeatureRouteContext context) => [
    GoRoute(
      path: OrganizationSettingsRoutes.general,
      builder: (context, state) => const GeneralSettingsPage(),
    ),
    GoRoute(
      path: OrganizationSettingsRoutes.legalDocuments,
      builder: (context, state) {
        final scope = state.extra is DocumentScope
            ? state.extra! as DocumentScope
            : DocumentScope.emiratesId;
        return BlocProvider(
          create: (_) => DocumentFlowBloc(
            config: organizationDocumentFlowConfigFor(scope),
            uploadMedia: sl<UploadMediaUseCase>(
              instanceName: organizationDocumentFlowInstance,
            ),
            extractDocuments: sl<ExtractDocumentsUseCase>(
              instanceName: organizationDocumentFlowInstance,
            ),
            submitDocuments: sl<SubmitDocumentsUseCase>(
              instanceName: organizationDocumentFlowInstance,
            ),
            fetchDocuments: sl<FetchDocumentsUseCase>(
              instanceName: organizationDocumentFlowInstance,
            ),
            validator: sl<DocumentTypeValidator>(),
          ),
          child: LegalDocumentsPage(scope: scope),
        );
      },
    ),
  ];
}
