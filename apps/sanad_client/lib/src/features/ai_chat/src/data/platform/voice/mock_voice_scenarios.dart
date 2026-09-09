/// Decides whether the assistant asks a card instead of talking, this turn.
///
/// Returns the raw `{schemaVersion, blocks}` payload, or `null` to speak as
/// usual. `turn` is 1 for the user's first utterance.
typedef AiVoiceUiScript = Map<String, dynamic>? Function(int turn);

/// The scripted semantic beats of a mocked voice conversation.
///
/// Live voice has no realtime backend, so there is nothing to *ask* for a
/// card. This supplies them on a fixed schedule instead — which is enough to
/// prove the part that matters: that a document can arrive mid-session, be
/// rendered by the shared renderer, be answered with an ordinary
/// `AiUiInteraction`, and let the session carry on. None of that is mocked;
/// only the decision to send a card is.
///
/// Opt-in. `MockAiVoiceSession` built without a script behaves exactly as it
/// did before — capture, echo, repeat — which is what keeps the existing mock
/// tests meaningful.
abstract final class MockVoiceScenarios {
  MockVoiceScenarios._();

  /// The default demo: slots, then a place, then a capability.
  ///
  /// Three turns because the three cover the three shapes an answer can take —
  /// a choice from a list, a structured place, and an outcome only the
  /// platform can produce.
  static Map<String, dynamic>? standard(int turn) => switch (turn) {
    1 => timeSlots,
    2 => locationPicker,
    3 => locationPermission,
    _ => null,
  };

  /// Never asks anything. The echo-only session the mock has always been.
  static Map<String, dynamic>? none(int turn) => null;

  /// "Which time works for you?"
  static const Map<String, dynamic> timeSlots = {
    'schemaVersion': 1,
    'blocks': [
      {
        'type': 'time_slots',
        'id': 'voice_slots',
        'dateLabel': 'Tomorrow',
        'slots': [
          {'id': 's_0900', 'label': '9:00 AM'},
          {'id': 's_1030', 'label': '10:30 AM'},
          {'id': 's_1400', 'label': '2:00 PM'},
        ],
        'confirmLabel': 'Confirm',
        'confirmTemplate': 'Book me the {slot} slot',
      },
    ],
  };

  /// "Where should I look?"
  static const Map<String, dynamic> locationPicker = {
    'schemaVersion': 1,
    'blocks': [
      {
        'type': 'location_picker',
        'id': 'voice_location',
        'title': 'Where should I look?',
        'useCurrentLabel': 'Use current location',
        'savedLabel': 'Saved',
        'savedLocations': [
          {
            'id': 'home',
            'name': 'Home',
            'addressText': 'Marina Tower 3, Dubai',
          },
          {
            'id': 'work',
            'name': 'Work',
            'addressText': 'Business Bay, Dubai',
          },
        ],
        'confirmLabel': 'Use this place',
        'confirmTemplate': 'Look around {location}',
      },
    ],
  };

  /// "I need your location for that."
  static const Map<String, dynamic> locationPermission = {
    'schemaVersion': 1,
    'blocks': [
      {
        'type': 'permission_request',
        'id': 'voice_permission',
        'permission': 'location',
        'title': 'Share your location?',
        'body': 'It helps me find services near you while we talk.',
        'allowLabel': 'Allow',
        'denyLabel': 'Not now',
      },
    ],
  };
}
