/// Shared contract primitives for the SANAD client-request lifecycle.
///
/// Deliberately narrow. The client and provider request payloads are
/// *intentionally different shapes* — a provider never sees rival offers or the
/// client's contact details — so the two request views are modelled separately,
/// in each app. Only what is byte-identical on both sides lives here:
///
/// * the lifecycle and offer-state enums,
/// * the attachment model,
/// * the negotiation bodies both roles POST (counter, cancel/dispute reason),
/// * the field limits and validators taken from the backend DTOs,
/// * the ISO-8601-with-offset codec, and
/// * the typed reader for the structured submission conflict.
///
/// Pure data and validation: no Flutter, no network, no widgets.
library;

export 'src/entities/request_attachment.dart';
export 'src/enums/client_request_status.dart';
export 'src/enums/request_offer_actor_type.dart';
export 'src/enums/request_offer_status.dart';
export 'src/requests/counter_offer_request.dart';
export 'src/requests/reason_request.dart';
export 'src/requests/request_field_limits.dart';
export 'src/requests/request_validators.dart';
export 'src/submission/request_submission_conflict.dart';
export 'src/time/api_date_time.dart';
