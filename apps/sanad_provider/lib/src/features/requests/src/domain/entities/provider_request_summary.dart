import 'package:equatable/equatable.dart';
import 'package:sanad_provider/src/features/requests/src/domain/enums/provider_request_tab.dart';

/// Badge counts, one per workspace tab.
///
/// Server-computed for the same reason the tab itself is: a paginated feed
/// cannot be counted client-side.
class ProviderRequestCounts extends Equatable {
  /// Creates a counts block.
  const ProviderRequestCounts({this.byTab = const {}});

  /// An empty set of counts.
  static const ProviderRequestCounts empty = ProviderRequestCounts();

  /// Count per tab. Absent tabs read as zero.
  final Map<ProviderRequestTab, int> byTab;

  /// The count for [tab], or zero.
  int of(ProviderRequestTab tab) => byTab[tab] ?? 0;

  @override
  List<Object?> get props => [byTab];
}

/// The four headline numbers above the workspace.
class ProviderRequestStats extends Equatable {
  /// Creates a stats block.
  const ProviderRequestStats({
    this.needsYourOffer = 0,
    this.awaitingClient = 0,
    this.scheduledToday = 0,
    this.completedThisMonth = 0,
  });

  /// Matched requests with no offer from this provider yet.
  final int needsYourOffer;

  /// Offers sent and not yet answered.
  final int awaitingClient;

  /// Bookings starting today.
  final int scheduledToday;

  /// Jobs completed since the start of this month.
  ///
  /// Replaces an earnings tile — no money passes through the platform in this
  /// release.
  final int completedThisMonth;

  @override
  List<Object?> get props => [
    needsYourOffer,
    awaitingClient,
    scheduledToday,
    completedThisMonth,
  ];
}
