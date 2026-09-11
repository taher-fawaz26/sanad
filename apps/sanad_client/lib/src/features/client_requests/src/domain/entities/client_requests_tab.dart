import 'package:requests_core/requests_core.dart';

/// The three segments the Requests screen is divided into — Figma
/// `StatusPills` (`8385:4377`): Active, Scheduled, Cancelled.
///
/// A tab is **not** a status. Two of the three map onto exactly one server
/// status and are filtered server-side; [active] is the catch-all and has no
/// single status to send, so it asks for everything and hides only what the
/// other two tabs already own. Nothing becomes unreachable that way: a
/// completed, disputed or expired request still appears under Active's
/// "Other requests", which is the only place left for it in a three-tab
/// design.
enum ClientRequestsTab {
  /// Live work — everything that is neither scheduled nor cancelled.
  active,

  /// Booked and waiting for its start time.
  scheduled,

  /// Called off, by either side.
  cancelled
  ;

  /// The `status` query parameter for this tab, or `null` to ask for all.
  ///
  /// `null` for [active] deliberately: `GET /requests?status=` takes a single
  /// value, and Active spans five. Inventing a repeated-parameter contract the
  /// backend has not been observed to support would be a worse trade than one
  /// unfiltered read.
  ClientRequestStatus? get serverStatus => switch (this) {
    ClientRequestsTab.active => null,
    ClientRequestsTab.scheduled => ClientRequestStatus.scheduled,
    ClientRequestsTab.cancelled => ClientRequestStatus.cancelled,
  };

  /// Whether [status] belongs on this tab.
  ///
  /// Only [active] actually has to ask: the other two are already narrowed by
  /// [serverStatus], so this answers `true` for whatever the server returned
  /// rather than second-guessing it.
  bool admits(ClientRequestStatus status) => switch (this) {
    ClientRequestsTab.active =>
      status != ClientRequestStatus.scheduled &&
          status != ClientRequestStatus.cancelled,
    ClientRequestsTab.scheduled || ClientRequestsTab.cancelled => true,
  };

  /// The i18n key for this tab's label.
  String get labelKey => switch (this) {
    ClientRequestsTab.active => 'client_requests.tab_active',
    ClientRequestsTab.scheduled => 'client_requests.tab_scheduled',
    ClientRequestsTab.cancelled => 'client_requests.tab_cancelled',
  };

  /// The i18n key for the heading over this tab's un-flagged rows — Figma
  /// `Other requests` / `Upcoming requests` / `Cancelled requests`
  /// (`8385:31885`, `8385:31891`, `8385:4636`).
  String get sectionKey => switch (this) {
    ClientRequestsTab.active => 'client_requests.section_other',
    ClientRequestsTab.scheduled => 'client_requests.section_upcoming',
    ClientRequestsTab.cancelled => 'client_requests.section_cancelled',
  };
}
