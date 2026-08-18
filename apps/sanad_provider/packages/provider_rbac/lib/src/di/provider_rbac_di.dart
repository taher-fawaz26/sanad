import 'package:core/core.dart';
import 'package:network/network.dart';
import 'package:provider_rbac/src/data/datasources/provider_rbac_remote_data_source.dart';
import 'package:provider_rbac/src/data/repositories/permissions_repository_impl.dart';
import 'package:provider_rbac/src/data/repositories/roles_repository_impl.dart';
import 'package:provider_rbac/src/domain/repositories/permissions_repository.dart';
import 'package:provider_rbac/src/domain/repositories/roles_repository.dart';
import 'package:provider_rbac/src/domain/usecases/assign_worker_roles_usecase.dart';
import 'package:provider_rbac/src/domain/usecases/create_role_usecase.dart';
import 'package:provider_rbac/src/domain/usecases/delete_role_usecase.dart';
import 'package:provider_rbac/src/domain/usecases/get_permissions_usecase.dart';
import 'package:provider_rbac/src/domain/usecases/get_roles_usecase.dart';
import 'package:provider_rbac/src/domain/usecases/get_worker_roles_usecase.dart';
import 'package:provider_rbac/src/domain/usecases/update_role_usecase.dart';
import 'package:provider_rbac/src/presentation/bloc/role_action/role_action_bloc.dart';
import 'package:provider_rbac/src/presentation/bloc/role_form/role_form_bloc.dart';
import 'package:provider_rbac/src/presentation/bloc/roles_list/roles_list_bloc.dart';
import 'package:provider_rbac/src/presentation/bloc/worker_roles/worker_roles_bloc.dart';
import 'package:provider_rbac/src/presentation/services/provider_rbac_worker_invite_roles_field.dart';
import 'package:provider_rbac/src/presentation/services/provider_rbac_worker_role_assigner.dart';
import 'package:provider_rbac/src/presentation/services/provider_rbac_worker_roles_tab.dart';
import 'package:workers/workers.dart';

abstract final class ProviderRbacDI {
  ProviderRbacDI._();

  static void init() {
    sl
      ..registerLazySingleton<ProviderRbacRemoteDataSource>(
        () => ProviderRbacRemoteDataSourceImpl(sl<BaseApiClient>()),
      )
      ..registerLazySingleton<RolesRepository>(
        () => RolesRepositoryImpl(sl<ProviderRbacRemoteDataSource>()),
      )
      ..registerLazySingleton<PermissionsRepository>(
        () => PermissionsRepositoryImpl(sl<ProviderRbacRemoteDataSource>()),
      )
      ..registerLazySingleton(() => GetRolesUseCase(sl<RolesRepository>()))
      ..registerLazySingleton(() => CreateRoleUseCase(sl<RolesRepository>()))
      ..registerLazySingleton(() => UpdateRoleUseCase(sl<RolesRepository>()))
      ..registerLazySingleton(() => DeleteRoleUseCase(sl<RolesRepository>()))
      ..registerLazySingleton(
        () => GetPermissionsUseCase(sl<PermissionsRepository>()),
      )
      ..registerLazySingleton(
        () => GetWorkerRolesUseCase(sl<RolesRepository>()),
      )
      ..registerLazySingleton(
        () => AssignWorkerRolesUseCase(sl<RolesRepository>()),
      )
      ..registerFactory(
        () => RolesListBloc(getRolesUseCase: sl<GetRolesUseCase>()),
      )
      ..registerFactory(
        () => RoleActionBloc(deleteRoleUseCase: sl<DeleteRoleUseCase>()),
      )
      ..registerFactory(
        () => RoleFormBloc(
          getPermissionsUseCase: sl<GetPermissionsUseCase>(),
          createRoleUseCase: sl<CreateRoleUseCase>(),
          updateRoleUseCase: sl<UpdateRoleUseCase>(),
        ),
      )
      ..registerFactory(
        () => WorkerRolesBloc(
          getWorkerRolesUseCase: sl<GetWorkerRolesUseCase>(),
          getRolesUseCase: sl<GetRolesUseCase>(),
          assignWorkerRolesUseCase: sl<AssignWorkerRolesUseCase>(),
        ),
      )
      // Implements the `workers`-defined port so worker_details_page can
      // render the "assigned roles" card without workers depending on this
      // package — see ProviderRbacWorkerRoleAssigner for details.
      ..registerLazySingleton<WorkerRoleAssigner>(
        () => const ProviderRbacWorkerRoleAssigner(),
      )
      // Renders the roles pane inline as the Workers screen's third tab.
      ..registerLazySingleton<WorkerRolesTabView>(
        () => const ProviderRbacWorkerRolesTab(),
      )
      // Implements the mandatory "Roles" field on the Add Member form —
      // see ProviderRbacWorkerInviteRolesField for details.
      ..registerLazySingleton<WorkerInviteRolesField>(
        () => const ProviderRbacWorkerInviteRolesField(),
      );
  }
}
