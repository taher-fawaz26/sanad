/// Where the mock agent is in the Home Cleaning journey.
///
/// The stage is the engine's *entire* memory. Everything it knows —
/// that a location was chosen, that photos arrived, that a booking is paid for
/// — is encoded here rather than duplicated as a bag of booleans, which is what
/// makes `AiJourneyEngine.reset` a one-line operation and what makes
/// "replaying a stage must not duplicate a card" a property of one value rather
/// than of a dozen.
enum AiJourneyStage {
  /// Nothing has been asked for yet. The journey starts from a natural
  /// sentence, never from a hidden control.
  idle,

  /// The user has asked for home cleaning; the agent has not answered yet.
  serviceRequested,

  /// A `location_picker` is on screen, waiting for an address.
  locationRequired,

  /// An address came back and was acknowledged.
  locationConfirmed,

  /// A `permission_request` for the camera is on screen.
  cameraPermissionRequired,

  /// A `media_request` is on screen, waiting for photos.
  mediaRequired,

  /// Photos arrived — either as a `media_result` or as real attachments.
  mediaReceived,

  /// A `provider_search` is on screen in its running state.
  searchingProviders,

  /// A `provider_card` carrying an offer is on screen.
  providersFound,

  /// The offer was accepted.
  offerSelected,

  /// A `booking_summary` plus its `confirm_prompt` are on screen.
  bookingSummary,

  /// The booking was confirmed.
  bookingConfirmed,

  /// A `payment_receipt` has been shown.
  paymentProcessed,

  /// An `appointment_card` has been shown.
  appointmentCreated,

  /// A `reminder_card` is on screen.
  reminderShown,

  /// The provider is assigned; the timeline is on its first active step.
  providerAssigned,

  /// The provider is travelling; the verification code has been shown.
  providerEnRoute,

  /// The job is under way.
  serviceInProgress,

  /// The job is finished.
  serviceCompleted,

  /// A `review_request` is on screen.
  reviewRequested,

  /// The journey is over.
  completed
  ;

  /// Stages that must never be entered twice in one run.
  ///
  /// The interaction ledger already stops a second tap on the same card, and
  /// the engine only accepts a signal the *current* stage expects — this is the
  /// third, independent guard, and the one that survives an operator
  /// hopping between scenarios mid-run. Without it, jumping to "Payment
  /// Successful" and walking back through the journey would print a second
  /// receipt.
  bool get isOneShot => switch (this) {
    AiJourneyStage.bookingConfirmed ||
    AiJourneyStage.paymentProcessed ||
    AiJourneyStage.appointmentCreated => true,
    _ => false,
  };
}
