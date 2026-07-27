/// Sanad Device — the single gateway to all device capabilities.
///
/// Features depend only on the types exported here; no feature may import
/// device plugins (device_info_plus, package_info_plus, connectivity_plus,
/// local_auth, share_plus, url_launcher) directly.
library;

export 'src/config/device_config.dart';
export 'src/device_facade.dart';
export 'src/di/device_di.dart';
export 'src/di/device_module.dart';
export 'src/domain/entities/app_info_data.dart';
export 'src/domain/entities/biometric_auth_result.dart';
export 'src/domain/entities/device_info_data.dart';
export 'src/domain/entities/share_result.dart';
export 'src/domain/enums/biometric_auth_status.dart';
export 'src/domain/enums/biometric_type.dart';
export 'src/domain/enums/connectivity_status.dart';
export 'src/domain/enums/share_status.dart';
export 'src/domain/services/app_info_service.dart';
export 'src/domain/services/biometric_service.dart';
export 'src/domain/services/clipboard_service.dart';
export 'src/domain/services/connectivity_service.dart';
export 'src/domain/services/device_info_service.dart';
export 'src/domain/services/share_service.dart';
export 'src/domain/services/url_launcher_service.dart';
