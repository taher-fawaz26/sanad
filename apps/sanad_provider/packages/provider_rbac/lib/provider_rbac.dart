/// Provider RBAC feature — public API surface.
///
/// - Role/permission domain entities and the RBAC-only [RolePersonaType]
///   enum (do not confuse with `auth`'s `UserType`).
/// - Repository contracts and use cases for role CRUD, the permission
///   catalog, and per-worker role assignment.
/// - [ProviderRbacModule] registers dependencies and contributes routes.
/// - Presentation: roles list / create / edit pages, and the "assigned
///   roles" worker-details card wired in via the `workers`-defined
///   `WorkerRoleAssigner` port.
library;

export 'src/data/endpoints/provider_rbac_api_paths.dart';
export 'src/di/provider_rbac_di.dart';
export 'src/domain/entities/permission_entity.dart';
export 'src/domain/entities/role_entity.dart';
export 'src/domain/entities/role_persona_type.dart';
export 'src/domain/repositories/permissions_repository.dart';
export 'src/domain/repositories/roles_repository.dart';
export 'src/domain/usecases/assign_worker_roles_usecase.dart';
export 'src/domain/usecases/create_role_usecase.dart';
export 'src/domain/usecases/delete_role_usecase.dart';
export 'src/domain/usecases/get_permissions_usecase.dart';
export 'src/domain/usecases/get_role_usecase.dart';
export 'src/domain/usecases/get_roles_usecase.dart';
export 'src/domain/usecases/get_worker_roles_usecase.dart';
export 'src/domain/usecases/remove_worker_role_usecase.dart';
export 'src/domain/usecases/update_role_usecase.dart';
export 'src/module/provider_rbac_module.dart';
export 'src/presentation/bloc/role_action/role_action_bloc.dart';
export 'src/presentation/bloc/role_form/role_form_bloc.dart';
export 'src/presentation/bloc/roles_list/roles_list_bloc.dart';
export 'src/presentation/bloc/worker_roles/worker_roles_bloc.dart';
export 'src/presentation/pages/role_details_page.dart';
export 'src/presentation/pages/role_form_page.dart';
export 'src/presentation/pages/roles_list_page.dart';
export 'src/presentation/widgets/permission_group_card.dart';
export 'src/presentation/widgets/role_actions_bottom_sheet.dart';
export 'src/presentation/widgets/role_list_item.dart';
export 'src/routes/provider_rbac_routes.dart';
