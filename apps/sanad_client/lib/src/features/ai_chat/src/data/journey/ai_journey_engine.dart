import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/journey/ai_journey_blocks.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/journey/ai_journey_fixtures.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/journey/ai_journey_signal.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/journey/ai_journey_stage.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/journey/ai_journey_step.dart';

/// The mock agent's mind: one deterministic Home Cleaning journey.
///
/// Pure and synchronous: no `Timer`, no `Stream`, no `BuildContext`, no clock
/// beyond the appointment fixture. That is what lets a unit test walk the whole
/// journey in microseconds and assert, stage by stage, that a card appears
/// exactly once.
///
/// It reads the **structured** answer on every card, never the sentence that
/// travelled beside it. Reading the prose would be the agent re-parsing its own
/// output, and the result would prove nothing about the interaction contract:
/// every branch below switches on `interaction.kind` and `interaction.value`.
///
/// Every payload it returns is an ordinary AI UI document built from the
/// protocol's own semantic node types, so what reaches the screen is whatever
/// `AiUiRenderer` already draws for a live agent. There is no second component
/// set and no mock-shaped node.
class AiJourneyEngine {
  /// Creates an engine resting at the start of the journey.
  AiJourneyEngine();

  AiJourneyStage _stage = AiJourneyStage.idle;

  /// Stages already visited in this run.
  ///
  /// The third and last duplicate guard, behind the interaction ledger and the
  /// "signal must match the current stage" rule. It is what keeps a card that
  /// is emitted from more than one branch — the receipt, the appointment —
  /// printed exactly once however the conversation arrives there.
  final Set<AiJourneyStage> _visited = <AiJourneyStage>{};

  /// Which offer is on the table. Incremented by a decline.
  int _offerIndex = 0;

  /// Where the journey currently rests.
  AiJourneyStage get stage => _stage;

  /// Forgets everything and returns to the opening position.
  ///
  /// Everything the engine remembers lives in the three fields above, so a
  /// reset really is total — there is no fourth place a stale provider
  /// selection or a spent permission result could hide.
  void reset() {
    _stage = AiJourneyStage.idle;
    _visited.clear();
    _offerIndex = 0;
  }

  /// Answers [signal], advancing at most one stage.
  ///
  /// An empty list means "this signal is not what the current stage is waiting
  /// for" — the transport then emits nothing at all, which is what makes a
  /// duplicate tap a genuine no-op rather than a second card.
  List<AiJourneyStep> respond(AiJourneySignal signal) {
    // A notice is answerable from wherever the conversation happens to be: it
    // reports something that happened to the request rather than asking the
    // next question in the sequence.
    final notice = _noticeResponse(signal);
    if (notice != null) return notice;

    return switch (_stage) {
      AiJourneyStage.idle => _atIdle(signal),
      AiJourneyStage.locationRequired => _atLocation(signal),
      AiJourneyStage.cameraPermissionRequired => _atPermission(signal),
      AiJourneyStage.mediaRequired => _atMedia(signal),
      AiJourneyStage.searchingProviders => _atSearch(signal),
      AiJourneyStage.providersFound => _atOffer(signal),
      AiJourneyStage.bookingSummary => _atBooking(signal),
      AiJourneyStage.reminderShown => _atReminder(signal),
      AiJourneyStage.providerAssigned => _advanceLifecycle(
        signal,
        to: AiJourneyStage.providerEnRoute,
      ),
      AiJourneyStage.providerEnRoute => _advanceLifecycle(
        signal,
        to: AiJourneyStage.serviceInProgress,
      ),
      AiJourneyStage.serviceInProgress => _advanceLifecycle(
        signal,
        to: AiJourneyStage.serviceCompleted,
      ),
      AiJourneyStage.reviewRequested => _atReview(signal),
      AiJourneyStage.completed => _atCompleted(signal),
      // Transient stages the machine passes through rather than rests at.
      _ => const [],
    };
  }

  // ── Stages ────────────────────────────────────────────────────────────────

  List<AiJourneyStep> _atIdle(AiJourneySignal signal) {
    if (signal is! AiJourneyTextSignal) return const [];

    if (!_startsJourney(signal)) {
      // Not silence and not a debug string: an agent that cannot place a
      // request says so and offers the way forward.
      return const [
        AiJourneyStep(
          prose:
              'I can help you book a home service. Tell me what you need and '
              'when — for example, a home cleaning tomorrow morning.',
        ),
      ];
    }

    return _moveTo(
      AiJourneyStage.locationRequired,
      through: const [AiJourneyStage.serviceRequested],
      steps: [
        AiJourneyStep(
          prose:
              'Sure — I can help with that. What location should we use for '
              'the service?',
          ui: [journeyLocationPickerBlock()],
        ),
      ],
    );
  }

  List<AiJourneyStep> _atLocation(AiJourneySignal signal) {
    if (signal is! AiJourneyInteractionSignal) return const [];

    final place = switch (signal.kind) {
      AiUiInteractionKind.locationSelected ||
      AiUiInteractionKind.locationConfirmed => _placeName(signal.interaction),
      // "Use current location" reaches the agent as a location *permission*
      // result on the client that cannot read a device position. Resolving it
      // to the fixture keeps the conversation moving rather than dead-ending.
      AiUiInteractionKind.permissionResult =>
        _isLocationPermission(signal.interaction)
            ? AiJourneyFixtures.locationShort
            : null,
      _ => null,
    };
    if (place == null) return const [];

    return _moveTo(
      AiJourneyStage.cameraPermissionRequired,
      through: const [AiJourneyStage.locationConfirmed],
      steps: [
        AiJourneyStep(
          prose:
              "I've got the location — $place. I just need access to a few "
              'photos so I can recommend the right provider.',
          ui: [journeyCameraPermissionBlock()],
        ),
      ],
    );
  }

  List<AiJourneyStep> _atPermission(AiJourneySignal signal) {
    if (signal is! AiJourneyInteractionSignal) return const [];
    if (signal.kind != AiUiInteractionKind.permissionResult) return const [];

    final value = signal.interaction.value;
    // A refused capability must not be re-offered on the next card, so the
    // outcome decides what the media prompt shows.
    final granted = value is AiUiPermissionValue && value.outcome.isGranted;

    return _moveTo(
      AiJourneyStage.mediaRequired,
      steps: [
        AiJourneyStep(
          prose: granted
              ? 'Great — add a few photos of the areas that need cleaning.'
              : "No problem, I'll work from your gallery instead. Pick a few "
                    'photos of the areas that need cleaning.',
          ui: [journeyMediaRequestBlock(cameraOffered: granted)],
        ),
      ],
    );
  }

  List<AiJourneyStep> _atMedia(AiJourneySignal signal) {
    final count = switch (signal) {
      AiJourneyAttachmentsSignal(:final count) => count,
      AiJourneyInteractionSignal(kind: AiUiInteractionKind.mediaResult) =>
        signal.interaction.value is AiUiMediaValue
            ? (signal.interaction.value as AiUiMediaValue).count
            : 0,
      _ => null,
    };
    if (count == null) return const [];

    if (count == 0) {
      // A refusal is a real answer. The agent carries on rather than asking
      // again, and the search still happens — just without the photos.
      return _moveTo(
        AiJourneyStage.providersFound,
        through: const [
          AiJourneyStage.mediaReceived,
          AiJourneyStage.searchingProviders,
        ],
        steps: [
          AiJourneyStep(
            prose:
                "No photos then — I'll go on the address alone and check who "
                'is nearby.',
            ui: [journeyProviderSearchBlock()],
          ),
          AiJourneyStep(
            prose: '${AiJourneyFixtures.providerName} can take this one:',
            ui: [journeyProviderOfferBlock()],
            context: journeyOffersContext(),
            thinkingDelay: const Duration(milliseconds: 2500),
          ),
        ],
      );
    }

    return _moveTo(
      AiJourneyStage.providersFound,
      through: const [
        AiJourneyStage.mediaReceived,
        AiJourneyStage.searchingProviders,
      ],
      steps: [
        AiJourneyStep(
          prose:
              'Thanks — got $count '
              "photo${count == 1 ? '' : 's'}. I'm checking "
              'nearby providers based on your location and the photos.',
          ui: [journeyProviderSearchBlock()],
        ),
        AiJourneyStep(
          prose: '${AiJourneyFixtures.providerName} can take this one:',
          ui: [journeyProviderOfferBlock()],
          context: journeyOffersContext(),
          // The beat that sells the search. Long enough to read the running
          // card, short enough that nobody on stage wonders if it hung.
          thinkingDelay: const Duration(milliseconds: 2500),
        ),
      ],
    );
  }

  List<AiJourneyStep> _atSearch(AiJourneySignal signal) {
    if (signal is! AiJourneyInteractionSignal) return const [];
    if (signal.kind != AiUiInteractionKind.confirmationResolved) {
      return const [];
    }

    final value = signal.interaction.value;
    final retry = value is AiUiConfirmationValue && value.confirmed;
    if (!retry) {
      _stage = AiJourneyStage.completed;
      return const [
        AiJourneyStep(
          prose:
              'Cancelled. Nothing has been booked, and you can start again '
              'whenever you like.',
        ),
      ];
    }

    _offerIndex = 0;
    return _moveTo(
      AiJourneyStage.providersFound,
      steps: [
        AiJourneyStep(
          prose:
              'I widened the window and found someone — '
              '${AiJourneyFixtures.providerName} can take it:',
          ui: [journeyProviderOfferBlock()],
          context: journeyOffersContext(),
        ),
      ],
    );
  }

  List<AiJourneyStep> _atOffer(AiJourneySignal signal) {
    if (signal is! AiJourneyInteractionSignal) return const [];
    if (signal.kind != AiUiInteractionKind.offerResolved) return const [];

    final value = signal.interaction.value;
    if (value is! AiUiOfferValue) return const [];

    if (value.decision == AiUiOfferDecision.accepted) {
      return _moveTo(
        AiJourneyStage.bookingSummary,
        through: const [AiJourneyStage.offerSelected],
        steps: [
          AiJourneyStep(
            prose: "Good choice. Here's the booking before I submit it:",
            ui: [journeyBookingSummaryBlock(), journeyBookingConfirmBlock()],
            clearsContext: true,
          ),
        ],
      );
    }

    _offerIndex += 1;
    if (_offerIndex > AiJourneyFixtures.alternates.length) {
      _stage = AiJourneyStage.searchingProviders;
      return [
        AiJourneyStep(
          prose:
              "That's everyone who is free for that slot. We can try a "
              'different time instead.',
          ui: [journeyNoProvidersBlock()],
          clearsContext: true,
        ),
      ];
    }

    // Stage deliberately unchanged: another offer is the same question asked
    // about a different provider, and the new card carries its own node id so
    // the ledger treats it as unanswered.
    return [
      AiJourneyStep(
        prose: "No problem — here's someone else who can take it:",
        ui: [journeyProviderOfferBlock(index: _offerIndex)],
      ),
    ];
  }

  List<AiJourneyStep> _atBooking(AiJourneySignal signal) {
    if (signal is! AiJourneyInteractionSignal) return const [];
    if (signal.kind != AiUiInteractionKind.confirmationResolved) {
      return const [];
    }

    final value = signal.interaction.value;
    final confirmed = value is AiUiConfirmationValue && value.confirmed;
    if (!confirmed) {
      _stage = AiJourneyStage.providersFound;
      return [
        AiJourneyStep(
          prose:
              "Nothing booked. Here's the offer again whenever you're "
              'ready:',
          ui: [journeyProviderOfferBlock(index: _offerIndex)],
        ),
      ];
    }

    // A second booking in the same run — reachable by answering a
    // `request_notice` and accepting a replacement offer. It confirms, but it
    // must not print a second receipt for a payment that already happened.
    // Silence would be worse: the user tapped Confirm and deserves an answer.
    if (_visited.contains(AiJourneyStage.paymentProcessed)) {
      _stage = AiJourneyStage.reminderShown;
      return const [
        AiJourneyStep(
          prose:
              "That's confirmed — same slot, same price, and nothing extra "
              'to '
              'pay. I will let you know when '
              '${AiJourneyFixtures.providerName} is on the way.',
        ),
      ];
    }

    return _moveTo(
      AiJourneyStage.reminderShown,
      through: const [
        AiJourneyStage.bookingConfirmed,
        AiJourneyStage.paymentProcessed,
        AiJourneyStage.appointmentCreated,
      ],
      steps: [
        AiJourneyStep(
          prose:
              "Your appointment is confirmed. I'll keep you updated as "
              '${AiJourneyFixtures.providerName} gets ready.',
          ui: [journeyAppointmentBlock()],
        ),
        AiJourneyStep(
          prose: 'Payment went through.',
          ui: [journeyPaymentReceiptBlock()],
          thinkingDelay: const Duration(milliseconds: 900),
        ),
        AiJourneyStep(
          prose: 'Your appointment is in 30 minutes.',
          ui: [journeyReminderBlock()],
          thinkingDelay: const Duration(milliseconds: 1200),
        ),
      ],
    );
  }

  List<AiJourneyStep> _atReminder(AiJourneySignal signal) {
    if (signal is! AiJourneyTextSignal) return const [];

    if (signal.hasAny(['reschedul'])) {
      // Answering without advancing: the lifecycle has not moved, so the stage
      // must not either.
      return const [
        AiJourneyStep(
          prose:
              'I can move it — tell me a day and time that suits you better '
              'and I will check availability.',
        ),
      ];
    }

    return _moveTo(
      AiJourneyStage.providerAssigned,
      steps: [
        AiJourneyStep(
          prose:
              '${AiJourneyFixtures.providerName} is assigned and getting '
              'ready.',
          ui: [journeyTimelineBlock(AiJourneyStage.providerAssigned)],
        ),
      ],
    );
  }

  List<AiJourneyStep> _advanceLifecycle(
    AiJourneySignal signal, {
    required AiJourneyStage to,
  }) {
    if (signal is! AiJourneyTextSignal) return const [];

    final prose = switch (to) {
      AiJourneyStage.providerEnRoute =>
        '${AiJourneyFixtures.providerName} is on the way — about 2.5 km out. '
            'Share this code with him when he arrives.',
      AiJourneyStage.serviceInProgress =>
        '${AiJourneyFixtures.providerName} has arrived and started the clean.',
      _ => 'Your service has been completed. How was your experience?',
    };

    final ui = <Map<String, dynamic>>[
      journeyTimelineBlock(to),
      if (to == AiJourneyStage.providerEnRoute) journeyVerificationCodeBlock(),
      if (to == AiJourneyStage.serviceCompleted) journeyReviewRequestBlock(),
    ];

    return _moveTo(
      to == AiJourneyStage.serviceCompleted
          ? AiJourneyStage.reviewRequested
          : to,
      through: to == AiJourneyStage.serviceCompleted
          ? const [AiJourneyStage.serviceCompleted]
          : const [],
      steps: [AiJourneyStep(prose: prose, ui: ui)],
    );
  }

  List<AiJourneyStep> _atReview(AiJourneySignal signal) {
    if (signal is! AiJourneyInteractionSignal) return const [];
    if (signal.kind != AiUiInteractionKind.reviewSubmitted) return const [];

    // Two shapes, one kind — a card with stars answers as a review value, one
    // without keeps the plain-text shape. Both are real answers.
    final (comment, rating) = switch (signal.interaction.value) {
      final AiUiReviewValue v => (v.comment, v.rating),
      final AiUiTextValue v => (v.text, null),
      _ => ('', null),
    };
    final stars = rating == null ? '' : ' $rating out of 5 —';
    final tail = comment.isEmpty ? '' : ' I have noted: "$comment".';

    _stage = AiJourneyStage.completed;
    return [
      AiJourneyStep(
        prose:
            'Thanks for your feedback.$stars$tail Your service journey is '
            'complete.',
      ),
    ];
  }

  List<AiJourneyStep> _atCompleted(AiJourneySignal signal) {
    if (signal is! AiJourneyTextSignal) return const [];
    return const [
      AiJourneyStep(
        prose:
            'That booking is all wrapped up. Say the word whenever you need '
            'another service and I will start a fresh request.',
      ),
    ];
  }

  // ── Notices ───────────────────────────────────────────────────────────────

  /// Answers a `request_notice` from any stage, or returns `null`.
  List<AiJourneyStep>? _noticeResponse(AiJourneySignal signal) {
    if (signal is! AiJourneyInteractionSignal) return null;
    if (signal.interaction.nodeType != AiUiNodeType.requestNotice) return null;
    if (signal.kind != AiUiInteractionKind.confirmationResolved) return null;

    final value = signal.interaction.value;
    final confirmed = value is AiUiConfirmationValue && value.confirmed;
    if (!confirmed) {
      return const [
        AiJourneyStep(
          prose:
              'Leaving it as it is. Tell me if you change your mind and I will '
              'pick it back up.',
        ),
      ];
    }

    _offerIndex = 0;
    _stage = AiJourneyStage.providersFound;
    return [
      AiJourneyStep(
        prose: 'On it — here is someone who can take the same slot:',
        ui: [journeyProviderOfferBlock()],
        context: journeyOffersContext(),
      ),
    ];
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Moves to [next], recording [through] as passed.
  ///
  /// [through] exists so every stage in `AiJourneyStage` means something even
  /// when
  /// the machine does not rest there: `bookingConfirmed`, `paymentProcessed`
  /// and `appointmentCreated` are all crossed by one Confirm tap, and marking
  /// them visited is what makes [AiJourneyStage.isOneShot] able to refuse a
  /// second
  /// receipt later in the run.
  List<AiJourneyStep> _moveTo(
    AiJourneyStage next, {
    required List<AiJourneyStep> steps,
    List<AiJourneyStage> through = const [],
  }) {
    for (final stage in [...through, next]) {
      if (stage.isOneShot && _visited.contains(stage)) return const [];
    }

    _visited
      ..addAll(through)
      ..add(next);
    _stage = next;
    return steps;
  }

  String? _placeName(AiUiInteraction interaction) {
    final value = interaction.value;
    return value is AiUiLocationValue ? value.name : null;
  }

  /// Whether this opening turn is a service request the journey can place.
  ///
  /// Intent matching on the *first* turn only: every stage after this reads a
  /// structured interaction instead. It is deliberately generous: a presenter
  /// paraphrasing the prompt should still land in the journey, and anything it
  /// misses gets the agent's "tell me what you need" reply rather than silence.
  bool _startsJourney(AiJourneyTextSignal signal) => signal.hasAny(const [
    'clean',
    'cleaning',
    'plumb',
    'ac ',
    'air con',
    'maintenance',
    'handyman',
    'service',
    'book',
    'need someone',
  ]);

  bool _isLocationPermission(AiUiInteraction interaction) {
    final value = interaction.value;
    return value is AiUiPermissionValue &&
        value.permission == AiUiPermissionKind.location.wire;
  }
}
