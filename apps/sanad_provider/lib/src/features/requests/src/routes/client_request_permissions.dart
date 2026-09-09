/// Backend permission identifiers for the provider request workspace.
///
/// Plain `static const String`, never an enum — the backend owns this
/// vocabulary and adds actions without a client release, so a closed set here
/// would go stale. Only the three the app actually gates are declared:
/// inventing a key that the backend does not issue would deny everyone.
///
/// Matches `BranchPermissions` / `ServicePermissions` / `WorkerPermissions`.
abstract final class ClientRequestPermissions {
  ClientRequestPermissions._();

  /// Counts, stats, list and detail.
  static const String view = 'provider:client-request:view';

  /// Create an offer, withdraw, accept, decline, counter.
  static const String offer = 'provider:client-request:offer';

  /// Mark a job finished, and cancel a booking.
  static const String complete = 'provider:client-request:complete';
}
