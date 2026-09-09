/// The provider half of the service-request lifecycle: a workspace of client
/// requests matched to this provider's branches, its own offer thread on each,
/// and the job actions that close them out.
///
/// Deliberately app-local, and deliberately *not* the client app's model. The
/// server returns a different shape here on purpose: rival offers are never
/// visible, and the client's contact details stay withheld until this provider
/// wins the booking. Only what is genuinely identical — the lifecycle enums,
/// the counter/reason bodies, the ISO-8601 codec — lives in
/// `package:requests_core`.
library;

export 'src/domain/entities/gated_contact.dart';
export 'src/domain/entities/provider_offer.dart';
export 'src/domain/entities/provider_request.dart';
export 'src/domain/entities/provider_request_summary.dart';
export 'src/domain/enums/provider_request_tab.dart';
export 'src/module/provider_requests_module.dart';
export 'src/routes/client_request_permissions.dart';
export 'src/routes/provider_request_routes.dart';
