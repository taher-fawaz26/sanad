/// The client half of the service-request lifecycle: draft, submit, negotiate,
/// confirm.
///
/// Deliberately app-local. The provider app models the same requests through a
/// *different* payload — a matched provider never sees rival offers, and never
/// sees the client's contact details until it wins the booking — so the two
/// views are built separately rather than sharing one model. Only what is
/// genuinely identical lives in `package:requests_core`.
library;

export 'src/domain/entities/catalogue_entities.dart';
export 'src/domain/entities/client_request.dart';
export 'src/domain/entities/matched_branch.dart';
export 'src/domain/entities/request_offer.dart';
export 'src/domain/entities/request_offer_thread.dart';
export 'src/module/client_requests_module.dart';
export 'src/routes/client_request_routes.dart';
