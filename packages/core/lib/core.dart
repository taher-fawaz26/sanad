/// Sanad Core — shared abstractions, validators, and cross-cutting
/// foundation utilities.
///
/// Exports: Failure hierarchy, Result/Either aliases, UseCase contracts,
/// DI helper, validators, extensions, and constants.
///
/// Asset path constants (`AppAssets`, `AppSvgs`, `AppImages`) live in the
/// `app_assets` package — `core` owns zero UI/asset knowledge by design.
library;

// Infrastructure BLoC utilities
export 'src/blocs/base_request_bloc.dart';
export 'src/blocs/base_request_state.dart';
// Bus abstractions
export 'src/bus/locale_change_bus.dart';
export 'src/di/service_locator.dart';
export 'src/domain/entities/entity_converter.dart';
export 'src/domain/failures/failure.dart';
export 'src/domain/failures/failure_extensions.dart';
export 'src/domain/usecases/usecase.dart';
export 'src/module/feature_module.dart';
export 'src/module/module_registry.dart';
export 'src/extensions/date_extensions.dart';
export 'src/extensions/string_extensions.dart';
export 'src/utils/constants/app_durations.dart';
export 'src/utils/constants/app_opacities.dart';
export 'src/utils/constants/defaults.dart';
export 'src/utils/constants/storage_keys.dart';
export 'src/utils/debounce.dart';
export 'src/utils/throttle.dart';
export 'src/utils/uuid_v4.dart';
export 'src/validators/date_validators.dart';
export 'src/validators/email_validator.dart';
export 'src/validators/emirates_id_validator.dart';
export 'src/validators/password_validator.dart';
export 'src/validators/person_name_validator.dart';
export 'src/validators/phone_validator.dart';
export 'src/validators/url_validator.dart';
