import 'package:flutter/widgets.dart';
import 'package:provider_rbac/src/presentation/widgets/roles_content.dart';
import 'package:workers/workers.dart';

/// Implements the `workers`-defined [WorkerRolesTabView] port so the Workers
/// screen can render the roles pane inline as its third tab without importing
/// `provider_rbac` — mirrors [ProviderRbacWorkerRoleAssigner].
class ProviderRbacWorkerRolesTab implements WorkerRolesTabView {
  const ProviderRbacWorkerRolesTab();

  @override
  Widget build() => const RolesContent();
}
