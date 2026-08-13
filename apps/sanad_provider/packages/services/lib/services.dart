/// Services feature — categories, catalog discovery, provider services CRUD
/// + status + images + overview, and service-requests, plus the
/// branch-service-assignment picker (sourced from the real catalog).
///
/// Public API surface:
/// * Register the module: add [ServicesModule] to the app [ModuleRegistry].
/// * Browse the catalog via [BrowseCatalogUseCase].
/// * Show picker: [showSelectServiceActionSheet].
/// * Provider dashboard UI: [ProviderServicesPage].
library;

export 'src/data/endpoints/services_api_paths.dart';
export 'src/di/services_di.dart';
export 'src/domain/entities/catalog_service_entity.dart';
export 'src/domain/entities/catalog_service_selection.dart';
export 'src/domain/entities/category_icon_entity.dart';
export 'src/domain/entities/category_record_entity.dart';
export 'src/domain/entities/category_ref_entity.dart';
export 'src/domain/entities/media_ref_entity.dart';
export 'src/domain/entities/pagination_meta_entity.dart';
export 'src/domain/entities/provider_service_entity.dart';
export 'src/domain/entities/provider_service_image_entity.dart';
export 'src/domain/entities/provider_service_overview_entity.dart';
export 'src/domain/entities/provider_service_status.dart';
export 'src/domain/entities/service_request_entity.dart';
export 'src/domain/entities/service_request_status.dart';
export 'src/domain/repositories/catalog_repository.dart';
export 'src/domain/repositories/categories_repository.dart';
export 'src/domain/repositories/provider_services_repository.dart';
export 'src/domain/repositories/service_requests_repository.dart';
export 'src/domain/usecases/add_provider_service_image_usecase.dart';
export 'src/domain/usecases/browse_catalog_usecase.dart';
export 'src/domain/usecases/create_provider_service_usecase.dart';
export 'src/domain/usecases/create_service_request_usecase.dart';
export 'src/domain/usecases/delete_provider_service_image_usecase.dart';
export 'src/domain/usecases/delete_provider_service_usecase.dart';
export 'src/domain/usecases/get_categories_usecase.dart';
export 'src/domain/usecases/get_my_service_requests_usecase.dart';
export 'src/domain/usecases/get_provider_service_usecase.dart';
export 'src/domain/usecases/get_provider_services_overview_usecase.dart';
export 'src/domain/usecases/get_service_request_usecase.dart';
export 'src/domain/usecases/list_provider_services_usecase.dart';
export 'src/domain/usecases/set_primary_provider_service_image_usecase.dart';
export 'src/domain/usecases/set_provider_service_status_usecase.dart';
export 'src/domain/usecases/update_provider_service_description_usecase.dart';
export 'src/module/services_module.dart';
export 'src/presentation/bloc/add_service/add_service_bloc.dart';
export 'src/presentation/bloc/edit_service/edit_service_bloc.dart';
export 'src/presentation/bloc/request_new_service/request_new_service_bloc.dart';
export 'src/presentation/bloc/service_action/service_action_bloc.dart';
export 'src/presentation/bloc/service_analytics/service_analytics_bloc.dart';
export 'src/presentation/bloc/service_requests_list/service_requests_list_bloc.dart';
export 'src/presentation/bloc/services_list/services_list_bloc.dart';
export 'src/presentation/models/provider_service_card_data.dart';
export 'src/presentation/pages/add_service_page.dart';
export 'src/presentation/pages/edit_service_page.dart';
export 'src/presentation/pages/request_new_service_page.dart';
export 'src/presentation/pages/services_page.dart';
export 'src/presentation/widgets/select_service_action_sheet.dart';
export 'src/presentation/widgets/service_list_card.dart';
export 'src/presentation/widgets/service_list_item.dart';
export 'src/presentation/widgets/service_metrics_section.dart';
export 'src/presentation/widgets/services_empty_state.dart';
export 'src/presentation/widgets/services_filter_bar.dart';
export 'src/routes/service_routes.dart';
