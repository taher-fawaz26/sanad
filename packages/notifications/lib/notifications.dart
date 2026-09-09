/// Mobile push and the in-app notification inbox.
///
/// Owns the app's only Firebase Messaging boundary, the device-token
/// registration lifecycle, the notification list, and the shared subject-based
/// tap routing with deduplication.
///
/// **The backend's SSE notification stream is deliberately not implemented.**
/// It is a web delivery channel: `EventSource` cannot send an Authorization
/// header, so it authenticates with a short-lived ticket and needs custom
/// reconnect handling. On mobile, FCM delivers while the app is backgrounded or
/// killed, and screens re-read their resource when they become active — which
/// also covers the transitions the server makes on timers rather than in
/// response to a tap. Nothing in this package opens a stream.
library;

export 'src/data/endpoints/notifications_api_paths.dart';
export 'src/data/models/notification_dto.dart';
export 'src/data/models/register_device_request.dart';
export 'src/data/platform/firebase_push_messaging_gateway.dart';
export 'src/di/notifications_di.dart';
export 'src/domain/entities/app_notification.dart';
export 'src/domain/entities/notification_subject.dart';
export 'src/domain/entities/push_message.dart';
export 'src/domain/enums/device_platform.dart';
export 'src/domain/enums/notification_subject_type.dart';
export 'src/domain/enums/notification_type.dart';
export 'src/domain/repositories/notifications_repository.dart';
export 'src/domain/services/push_messaging_gateway.dart';
export 'src/domain/usecases/get_notifications_usecase.dart';
export 'src/domain/usecases/mark_all_notifications_read_usecase.dart';
export 'src/domain/usecases/mark_notification_read_usecase.dart';
export 'src/domain/usecases/notifications_query.dart';
export 'src/domain/usecases/register_device_usecase.dart';
export 'src/domain/usecases/unregister_device_usecase.dart';
export 'src/module/notifications_module.dart';
export 'src/navigation/notification_dedup_store.dart';
export 'src/navigation/notification_navigator.dart';
export 'src/presentation/bloc/notifications/notifications_bloc.dart';
export 'src/presentation/pages/notifications_page.dart';
export 'src/push/local_notification_presenter.dart';
export 'src/push/push_notification_router.dart';
export 'src/push/push_registration_coordinator.dart';
export 'src/routes/notifications_routes.dart';
