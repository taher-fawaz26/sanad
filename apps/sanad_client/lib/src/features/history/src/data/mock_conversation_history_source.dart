import 'package:sanad_client/src/features/history/src/domain/conversation_history_entry.dart';
import 'package:sanad_client/src/features/history/src/domain/conversation_history_source.dart';

/// Which fixture set [MockConversationHistorySource] serves.
///
/// The two states in Figma (`8120:2918` populated, `8124:3867` empty) are two
/// renderings of one screen, so they are selected by *data* rather than by a
/// second route: an empty list is the empty state, and nothing about the page
/// branches on a flag.
enum ConversationHistoryFixture {
  /// Figma `8120:2918` — a scrollable list of past conversations.
  populated,

  /// Figma `8124:3867` — no previous conversations.
  empty
  ;

  /// Reads the fixture from the dev route's `?state=` query parameter,
  /// following the `?mock=`/`?transport=` affordances already on the chat
  /// route. Anything unrecognised (including nothing at all) is [populated].
  static ConversationHistoryFixture fromQuery(String? value) =>
      value == 'empty' ? empty : populated;
}

/// Local fixtures standing in for the history endpoint that does not exist
/// yet.
///
/// Reachable only through the `/dev`-namespaced History route, which
/// `AiChatModule` registers under `!kReleaseMode` — so no mock copy can reach
/// a release build, and no dev-only flag has to be threaded through the app to
/// keep it out.
///
/// The content is not filler. It carries the variation the list has to survive
/// — a title longer than the row is wide, a one-word title, a preview that
/// fits on one line and previews that overflow two — because those are the
/// cases where the card's own layout decisions (ellipsis, `maxLines`, the
/// title yielding width to the timestamp) either hold or do not.
class MockConversationHistorySource implements ConversationHistorySource {
  /// Creates the source.
  ///
  /// [now] anchors the relative timestamps; it exists so a test can assert
  /// "Today" and "Yesterday" without depending on the wall clock.
  const MockConversationHistorySource({
    this.fixture = ConversationHistoryFixture.populated,
    this.now,
  });

  /// Which fixture set to serve.
  final ConversationHistoryFixture fixture;

  /// The instant the fixtures are dated relative to. Defaults to the clock.
  final DateTime? now;

  @override
  List<ConversationHistoryEntry> load() => switch (fixture) {
    ConversationHistoryFixture.empty => const [],
    ConversationHistoryFixture.populated => _entries(now ?? DateTime.now()),
  };

  /// Figma's five cards, then five more so the list actually scrolls and the
  /// card's text-overflow behaviour is visible rather than assumed.
  static List<ConversationHistoryEntry> _entries(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    DateTime at(int dayOffset, int hour, int minute) =>
        today.add(Duration(days: dayOffset, hours: hour, minutes: minute));

    return [
      ConversationHistoryEntry(
        id: 'emirates-id-renewal',
        title: 'Emirates ID Renewal',
        preview:
            'Renewal request sent successfully. Your reference number: '
            'REF-2024-4821.',
        updatedAt: at(0, 14, 30),
      ),
      ConversationHistoryEntry(
        id: 'flight-tickets',
        title: 'Flight Tickets',
        preview:
            'Your flight to Dubai has been booked successfully, departing '
            'Friday, September 15.',
        updatedAt: at(-1, 15, 45),
      ),
      ConversationHistoryEntry(
        id: 'travel-trips',
        title: 'Travel Trips',
        preview:
            'Your trip to Sharm El Sheikh is confirmed! Starts Saturday, '
            'includes accommodation and transfers.',
        updatedAt: at(-1, 11, 20),
      ),
      ConversationHistoryEntry(
        id: 'home-services',
        title: 'Home Services',
        preview:
            'Your home cleaning service has been confirmed for next Thursday '
            'at 10 AM.',
        updatedAt: at(0, 9, 30),
      ),
      ConversationHistoryEntry(
        id: 'visa-application-status',
        title: 'Visa Application Status',
        preview:
            'Your visa application is under review. Expected decision by '
            'next week.',
        updatedAt: at(1, 9, 0),
      ),
      // A title wider than the row: the header must give the timestamp its
      // space and ellipsize the title, not overflow.
      ConversationHistoryEntry(
        id: 'vehicle-registration',
        title: 'Vehicle Registration Renewal and Insurance Transfer',
        preview:
            'Both renewals are linked to plate A-48219. Payment is pending '
            'until the inspection certificate is uploaded.',
        updatedAt: at(-2, 16, 5),
      ),
      // The shortest possible card: one-word title, one-line preview.
      ConversationHistoryEntry(
        id: 'rent',
        title: 'Rent',
        preview: 'Paid.',
        updatedAt: at(-3, 8, 15),
      ),
      // Long enough to be cut by the preview's two-line cap.
      ConversationHistoryEntry(
        id: 'school-enrolment',
        title: 'School Enrolment',
        preview:
            'The enrolment window for the next academic year opens on 3 '
            'October and closes on 28 October. You will need the birth '
            'certificate, two passport photographs, the vaccination record '
            'and last year’s report card before you can submit.',
        updatedAt: at(-5, 13, 40),
      ),
      ConversationHistoryEntry(
        id: 'utility-transfer',
        title: 'Utility Transfer',
        preview:
            'Electricity and water are now registered to the new address, '
            'effective from the first of the month.',
        updatedAt: at(-9, 10, 55),
      ),
      ConversationHistoryEntry(
        id: 'health-insurance-card',
        title: 'Health Insurance Card',
        preview:
            'A replacement card is on its way and should arrive in about '
            'five working days.',
        updatedAt: at(-21, 17, 25),
      ),
    ];
  }
}
