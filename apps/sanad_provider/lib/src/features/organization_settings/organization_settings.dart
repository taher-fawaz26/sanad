/// Provider-only organization settings — KPI hub, menu sheet, placeholders.
///
/// Register [OrganizationSettingsModule] in the provider [ModuleRegistry].
/// Navigate via [OrganizationSettingsRoutes]. Open the settings entry sheet
/// with [showSettingsMenuSheet].
library;

export 'src/di/organization_settings_di.dart';
export 'src/domain/entities/organization_media_slot.dart';
export 'src/module/organization_settings_module.dart';
export 'src/presentation/bloc/identity_header/identity_header_bloc.dart';
export 'src/presentation/bloc/organization_settings/organization_settings_bloc.dart';
export 'src/presentation/bloc/provider_overview/provider_overview_bloc.dart';
export 'src/presentation/pages/general_settings_page.dart';
export 'src/presentation/pages/organization_settings_page.dart';
export 'src/presentation/widgets/bottom_sheets/add_or_change_email_sheet.dart';
export 'src/presentation/widgets/bottom_sheets/add_or_change_phone_sheet.dart';
export 'src/presentation/widgets/settings_menu_sheet.dart';
export 'src/routes/organization_settings_routes.dart';
