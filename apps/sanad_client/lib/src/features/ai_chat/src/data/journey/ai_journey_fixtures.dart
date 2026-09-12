/// The single data set every card in the mock journey is built from.
///
/// One story, told the same way everywhere. The reason this is a class of
/// constants rather than values inlined per card is the failure it prevents:
/// a card set assembled piecemeal drifts — a Dubai address on one card, another
/// city on the next, two service names between them — which reads fine as a
/// component gallery and falls apart the moment the cards are meant to be the
/// *same* booking.
abstract final class AiJourneyFixtures {
  /// The service being booked, everywhere it is named.
  static const service = 'Home Cleaning';

  /// The saved place the journey uses.
  static const locationName = 'Home';

  /// Its street line.
  static const locationAddress = 'Dubai Marina, Tower 5, Apt 1204';

  /// The short form used where a card has room for a place but not an address.
  static const locationShort = 'Dubai Marina';

  /// The saved place's id, echoed back in the `location_selected` value.
  static const locationId = 'home';

  /// A maps query — an address, never a URL.
  static const mapQuery = 'Dubai Marina, Tower 5, Dubai';

  /// Where the real map opens.
  ///
  /// A **camera hint only**. The user still pans, searches and confirms on the
  /// live map, and the confirmed point comes from there — this just spares a
  /// presenter scrolling in from the country-level default. Dubai Marina.
  static const cameraLatitude = 25.0805;

  /// Longitude for [cameraLatitude].
  static const cameraLongitude = 55.1403;

  /// The primary provider.
  static const providerId = 'prv_ahmed';

  /// Their display name.
  static const providerName = 'Ahmed K';

  /// Their speciality line.
  static const providerRole = 'AC & Plumbing Specialist';

  /// Their published rating, 0–5.
  static const providerRating = 4.8;

  /// Jobs completed, as the card prints it.
  static const providerJobs = '340+';

  /// Distance in metres; the renderer formats and localizes the unit.
  static const providerDistanceMetres = 2500;

  /// How many offers the request has drawn, as the contextual affordance
  /// prints it. More than the two on the card: the surface summarises the
  /// whole request, and opening it shows the ones worth reading first.
  static const offerCount = 8;

  /// The offer's id, echoed back in the `offer_resolved` value.
  static const offerId = 'off_hc_8829';

  /// What the appointment costs, as printed.
  static const priceLabel = '150 AED';

  /// The same amount, structured for the receipt's total.
  ///
  /// A number, not a string: `AiUiMoney.amount` is numeric and the renderer
  /// owns the formatting, so the currency lands in the right place in Arabic
  /// as well as English. Writing it as text validated clean in isolation and
  /// dropped the total on the receipt.
  static const priceAmount = 150.0;

  /// Its currency.
  static const currency = 'AED';

  /// How the appointment slot reads on a card.
  static const appointmentLabel = 'Tomorrow · 10:00 AM';

  /// The booking's human reference.
  static const bookingReference = '#SND-8829-AQ';

  /// The payment instrument, as the receipt prints it.
  static const paymentMethod = 'Apple Pay ending in 4920';

  /// The payment's transaction id.
  static const transactionId = 'TXN-8829410';

  /// The completion code the user reads out to the provider.
  static const verificationCode = '65066';

  /// The request's id, used as a confirmation `reference`.
  static const requestReference = 'req_hc_8829';

  /// Tomorrow at 10:00 local time.
  ///
  /// Computed rather than hard-coded because `appointment_card.startsAt` is a
  /// real instant the *client* formats — a frozen date would print "Tomorrow"
  /// beside a date months in the past.
  static DateTime get appointmentAt {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 10);
  }

  /// [appointmentAt] on the wire: ISO-8601, UTC, as the protocol requires.
  static String get appointmentAtIso => appointmentAt.toUtc().toIso8601String();

  /// The alternate providers offered when the first is declined.
  ///
  /// Same city, same service, same price band — declining must not silently
  /// move the story somewhere else.
  static const alternates = <AiJourneyProvider>[
    AiJourneyProvider(
      id: 'prv_carlos',
      name: 'Carlos R',
      role: 'Landscape Designer',
      rating: 4.6,
      jobs: '150+',
      distanceMetres: 5100,
      offerId: 'off_hc_8831',
    ),
    AiJourneyProvider(
      id: 'prv_lina',
      name: 'Lina M',
      role: 'Deep Cleaning Specialist',
      rating: 4.7,
      jobs: '210+',
      distanceMetres: 3200,
      offerId: 'off_hc_8830',
    ),
  ];
}

/// A provider in the journey's cast.
final class AiJourneyProvider {
  /// Creates a provider fixture.
  const AiJourneyProvider({
    required this.id,
    required this.name,
    required this.role,
    required this.rating,
    required this.jobs,
    required this.distanceMetres,
    required this.offerId,
  });

  /// Stable id, echoed in `offer_resolved`.
  final String id;

  /// Display name.
  final String name;

  /// Speciality line.
  final String role;

  /// Published rating, 0–5.
  final double rating;

  /// Jobs completed, as printed.
  final String jobs;

  /// Distance in metres.
  final int distanceMetres;

  /// This provider's offer id.
  final String offerId;
}
