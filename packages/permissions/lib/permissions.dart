/// Sanad Permissions — the single source of truth for runtime permission
/// management across the entire monorepo.
///
/// Features depend only on the types exported here; no feature may import
/// `permission_handler` directly.
library;

export 'src/config/permission_config.dart';
export 'src/di/permissions_di.dart';
export 'src/di/permissions_module.dart';
export 'src/domain/entities/permission_group.dart';
export 'src/domain/entities/permission_request.dart';
export 'src/domain/entities/permission_result.dart';
export 'src/domain/enums/permission_status.dart';
export 'src/domain/enums/permission_type.dart';
export 'src/domain/services/permission_service.dart';
export 'src/permission_flow.dart';
export 'src/permissions_facade.dart';
export 'src/theme/permission_explanation.dart';
export 'src/theme/permission_theme.dart';
