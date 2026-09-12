/// Every block the mock agent can send, in wire shape.
///
/// Raw `Map<String, dynamic>` on purpose: building typed nodes here would
/// bypass `AiUiValidator`, and the whole point is that these payloads are held
/// to exactly the policy a live agent's are — the same action allowlist, the
/// same asset allowlist, the same limits. A block that would be refused from
/// the backend is refused from here too, and `ai_journey_blocks_test.dart` is
/// what keeps that honest.
///
/// Every `type` below is an existing AI UI Protocol v1 semantic node with an
/// existing renderer. Nothing here is invented for the mock.
library;

import 'package:sanad_client/src/features/ai_chat/src/data/journey/ai_journey_fixtures.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/journey/ai_journey_stage.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/journey/ai_journey_step.dart';

/// Wraps [blocks] in a `ui` payload envelope.
Map<String, dynamic> journeyPayload(List<Map<String, dynamic>> blocks) =>
    <String, dynamic>{'schemaVersion': 1, 'blocks': blocks};

/// `location_picker` — the saved place plus the device's own location.
Map<String, dynamic> journeyLocationPickerBlock() => <String, dynamic>{
  'type': 'location_picker',
  'id': 'journey_location_picker',
  'title': 'Set your location',
  'searchPlaceholder': 'Search for a neighborhood or city...',
  'useCurrentLabel': 'Use current location',
  'savedLabel': 'Saved locations',
  'savedLocations': [
    {
      'id': AiJourneyFixtures.locationId,
      'name': AiJourneyFixtures.locationName,
      'addressText': AiJourneyFixtures.locationAddress,
      'icon': 'fa-solid fa-house',
    },
    {
      'id': 'office',
      'name': 'Office',
      'addressText': 'DIFC, The Gate District, Level 4',
      'icon': 'fa-solid fa-briefcase',
    },
  ],
  'confirmLabel': 'Confirm',
  'confirmTemplate': 'Use {location} as the service address',
  'fallbackText': 'Which address should I use?',
};

/// `permission_request` — the camera variant.
Map<String, dynamic> journeyCameraPermissionBlock() => <String, dynamic>{
  'type': 'permission_request',
  'id': 'journey_permission_camera',
  'permission': 'camera',
  'title': 'Allow camera access?',
  'body':
      'Sanad needs your camera so you can show me the areas that need '
      'cleaning. You can change this later in settings.',
  'allowLabel': 'Allow camera',
  'denyLabel': 'Not now',
  'fallbackText': 'Sanad needs camera access to continue',
};

/// `media_request` — how the photos arrive.
///
/// [cameraOffered] is false once the camera has been refused: re-offering a
/// capability the user has just declined is how a prompt becomes nagging, and
/// the gallery route reaches the same place.
Map<String, dynamic> journeyMediaRequestBlock({bool cameraOffered = true}) =>
    <String, dynamic>{
      'type': 'media_request',
      'id': 'journey_media_request',
      'title': 'Add photos of the areas',
      'body':
          'Three or four photos are plenty — they help me match you with the '
          'right provider.',
      'options': [
        if (cameraOffered) {'label': 'Take a photo', 'source': 'camera'},
        {'label': 'Choose photos', 'source': 'gallery'},
      ],
      'cancelLabel': 'Skip for now',
      'fallbackText': 'Send a few photos of the areas that need cleaning',
    };

/// `provider_search` in its running state.
Map<String, dynamic> journeyProviderSearchBlock() => <String, dynamic>{
  'type': 'provider_search',
  'id': 'journey_provider_search',
  'statusLabel': 'Finding providers...',
  'title': 'Searching nearby providers',
  'body':
      "We're matching your request with available providers around "
      '${AiJourneyFixtures.locationShort}.',
  // No `progress`: a provider search has no meaningful percentage, and the
  // running card is deliberately indeterminate.
  'fallbackText': 'Searching for providers near you',
};

/// `provider_search` once every provider has been tried.
Map<String, dynamic> journeyNoProvidersBlock() => <String, dynamic>{
  'type': 'provider_search',
  'id': 'journey_provider_search_exhausted',
  'state': 'exhausted',
  'title': 'No Specialists Available',
  'body':
      'No active providers could match your '
      '${AiJourneyFixtures.service} request '
      'for that slot.',
  'confirm': {
    'confirmLabel': 'Change Time Slot',
    'cancelLabel': 'Cancel',
    'confirmTemplate': 'Let us try a different time',
    'cancelTemplate': 'Cancel this request',
    'reference': AiJourneyFixtures.requestReference,
  },
  'fallbackText': 'No specialists are available for that slot',
};

/// `provider_card` carrying the offer.
///
/// [index] 0 is the primary provider; 1 and up are the alternates offered after
/// a decline. The node id varies with the index so a declined card and its
/// replacement are distinct as far as the interaction ledger is concerned —
/// reusing one id would leave the second offer rendered in the first one's
/// already-resolved state.
Map<String, dynamic> journeyProviderOfferBlock({int index = 0}) {
  final isPrimary = index == 0;
  final alternate = isPrimary
      ? null
      : AiJourneyFixtures.alternates[(index - 1) %
            AiJourneyFixtures.alternates.length];

  return <String, dynamic>{
    'type': 'provider_card',
    'id': 'journey_provider_offer_$index',
    'providerId': alternate?.id ?? AiJourneyFixtures.providerId,
    'name': alternate?.name ?? AiJourneyFixtures.providerName,
    'roleText': alternate?.role ?? AiJourneyFixtures.providerRole,
    'ratingValue': alternate?.rating ?? AiJourneyFixtures.providerRating,
    'verified': true,
    'presentation': 'expanded',
    'image': const {'assetId': 'ai_provider_avatar'},
    'proposedTimeLabel': 'Proposed Time',
    // Structured and in UTC: the client converts to device time and formats it,
    // so the slot on the card is never a string the agent typed.
    'proposedTime': AiJourneyFixtures.appointmentAtIso,
    'distanceMeters':
        alternate?.distanceMetres ?? AiJourneyFixtures.providerDistanceMetres,
    'description': isPrimary
        ? 'Ten years of residential cleaning around Dubai Marina. Brings his '
              'own eco-friendly products and handles AC and plumbing call-outs '
              'on the same visit.'
        : 'Available for your slot and works the same area.',
    'stats': [
      {
        'label': 'Completed jobs',
        'value': alternate?.jobs ?? AiJourneyFixtures.providerJobs,
      },
      {'label': 'Estimated cost', 'value': AiJourneyFixtures.priceLabel},
    ],
    'services': const ['Deep clean', 'Kitchen', 'Bathrooms'],
    'servicesLabel': 'Services',
    if (isPrimary)
      'photos': const [
        {'assetId': 'work_photo_ac'},
        {'assetId': 'work_photo_plumbing'},
        {'assetId': 'work_photo_electrical'},
      ],
    'offer': {
      'offerId': alternate?.offerId ?? AiJourneyFixtures.offerId,
      'acceptLabel': 'Accept Offer',
      'declineLabel': 'Decline',
      'acceptTemplate':
          "I'll take "
          "${alternate?.name ?? AiJourneyFixtures.providerName}'s offer",
      'declineTemplate': 'Not this one, thanks',
    },
    'fallbackText':
        '${alternate?.name ?? AiJourneyFixtures.providerName} offers '
        '${AiJourneyFixtures.appointmentLabel} — accept or decline',
  };
}

/// `booking_summary` — the review before anything is committed.
Map<String, dynamic> journeyBookingSummaryBlock() => <String, dynamic>{
  'type': 'booking_summary',
  'id': 'journey_booking_summary',
  'title': 'Booking Summary',
  'provider': {
    'providerId': AiJourneyFixtures.providerId,
    'name': AiJourneyFixtures.providerName,
    'roleText': AiJourneyFixtures.providerRole,
    'image': {'assetId': 'ai_provider_avatar'},
    'verified': true,
  },
  'items': [
    {'label': 'Service', 'value': AiJourneyFixtures.service},
    {'label': 'Provider', 'value': AiJourneyFixtures.providerName},
    {'label': 'When', 'value': AiJourneyFixtures.appointmentLabel},
    {'label': 'Location', 'value': AiJourneyFixtures.locationAddress},
    {
      'label': 'Estimated Cost',
      'value': AiJourneyFixtures.priceLabel,
      'valueTone': 'primary',
    },
  ],
  'fallbackText':
      '${AiJourneyFixtures.service} with ${AiJourneyFixtures.providerName} — '
      '${AiJourneyFixtures.priceLabel}',
};

/// `confirm_prompt` — the decision that commits the booking.
///
/// A separate node from the summary above it, and deliberately so: the summary
/// is something to read, the prompt is something to answer. Answering it
/// produces a real `confirmation_resolved` interaction carrying the request
/// reference, which a pair of `send_message` buttons could not.
Map<String, dynamic> journeyBookingConfirmBlock() => <String, dynamic>{
  'type': 'confirm_prompt',
  'id': 'journey_booking_confirm',
  'title': 'Confirm this booking?',
  'subjectTitle': AiJourneyFixtures.service,
  'subjectSubtitle':
      '${AiJourneyFixtures.providerName} • '
      '${AiJourneyFixtures.appointmentLabel}',
  'confirm': {
    'confirmLabel': 'Confirm',
    'cancelLabel': 'Go Back',
    'confirmTemplate': 'Confirm the booking',
    'cancelTemplate': 'Let me look again',
    'reference': AiJourneyFixtures.requestReference,
  },
  'fallbackText': 'Confirm your ${AiJourneyFixtures.service} booking?',
};

/// `appointment_card` — the booking, once it exists.
Map<String, dynamic> journeyAppointmentBlock() => <String, dynamic>{
  'type': 'appointment_card',
  'id': 'journey_appointment',
  'appointmentId': 'apt_hc_8829',
  'title': AiJourneyFixtures.service,
  'startsAt': AiJourneyFixtures.appointmentAtIso,
  'whereText': AiJourneyFixtures.locationAddress,
  'status': 'Confirmed',
  'statusTone': 'success',
  'actions': [
    {
      'label': 'Open in Maps',
      'variant': 'outline',
      'action': {'type': 'open_map', 'query': AiJourneyFixtures.mapQuery},
    },
  ],
  'fallbackText':
      '${AiJourneyFixtures.service} confirmed for '
      '${AiJourneyFixtures.appointmentLabel}',
};

/// `payment_receipt` — the settled payment.
Map<String, dynamic> journeyPaymentReceiptBlock() => <String, dynamic>{
  'type': 'payment_receipt',
  'id': 'journey_payment_receipt',
  'title': 'Payment Successful',
  'subtitle': AiJourneyFixtures.service,
  'items': [
    // Marked LTR so the reference reads correctly in Arabic — the SAN-770
    // class of bug.
    {
      'label': 'Transaction ID',
      'value': AiJourneyFixtures.transactionId,
      'isLtrValue': true,
    },
    {'label': 'Payment Method', 'value': AiJourneyFixtures.paymentMethod},
    {
      'label': 'Booking Reference',
      'value': AiJourneyFixtures.bookingReference,
      'isLtrValue': true,
    },
  ],
  'total': {
    'label': 'Amount Paid',
    'amount': {
      'amount': AiJourneyFixtures.priceAmount,
      'currency': AiJourneyFixtures.currency,
    },
  },
  'fallbackText':
      'Payment successful — ${AiJourneyFixtures.priceLabel} — '
      '${AiJourneyFixtures.transactionId}',
};

/// `reminder_card` — the heads-up before the visit.
Map<String, dynamic> journeyReminderBlock() => <String, dynamic>{
  'type': 'reminder_card',
  'id': 'journey_reminder',
  'title': 'Reminder',
  'subtitle': AiJourneyFixtures.service,
  'body':
      'Your appointment is in 30 minutes. Please make sure someone is home to '
      'let ${AiJourneyFixtures.providerName} in.',
  'tone': 'warning',
  'actions': [
    {
      'label': 'Reschedule',
      'variant': 'outline',
      'action': {'type': 'send_message', 'text': 'Reschedule my appointment'},
    },
    {
      'label': "I'm ready",
      'action': {'type': 'send_message', 'text': "I'm ready"},
    },
  ],
  'fallbackText': 'Reminder: ${AiJourneyFixtures.service} in 30 minutes',
};

/// `service_timeline` for [stage], with the action that advances it.
///
/// One node for the whole lifecycle rather than a card per step — which is the
/// point the protocol's `service_timeline` makes, and the reason the journey
/// needs
/// no lifecycle UI of its own. The trailing action is what makes the journey
/// tap-driven: each step waits for the operator rather than running away on a
/// timer nobody can pause on stage.
Map<String, dynamic> journeyTimelineBlock(AiJourneyStage stage) {
  String stateAt(AiJourneyStage step) {
    if (stage.index > step.index) return 'completed';
    return stage.index == step.index ? 'active' : 'pending';
  }

  final advance = switch (stage) {
    AiJourneyStage.providerAssigned => (
      'Provider is on the way',
      'Ahmed is on the way',
    ),
    AiJourneyStage.providerEnRoute => (
      'Ahmed has arrived',
      'Ahmed has arrived',
    ),
    AiJourneyStage.serviceInProgress => (
      'Mark service completed',
      'The service is complete',
    ),
    _ => null,
  };

  final isDone = stage.index >= AiJourneyStage.serviceCompleted.index;

  return <String, dynamic>{
    'type': 'service_timeline',
    'id': 'journey_timeline_${stage.name}',
    'title': 'Service Timeline',
    'status': isDone ? 'Completed' : 'In Progress',
    'statusTone': isDone ? 'success' : 'info',
    'items': [
      {
        'state': 'completed',
        'title': 'Booking Confirmed',
        'description': 'Your booking has been confirmed',
      },
      {
        'state': stateAt(AiJourneyStage.providerAssigned),
        'title': 'Provider Assigned',
        'description':
            '${AiJourneyFixtures.providerName} is assigned to your job',
      },
      {
        'state': stateAt(AiJourneyStage.providerEnRoute),
        'title': 'En Route',
        'description': 'Provider is on the way',
      },
      {
        'state': stateAt(AiJourneyStage.serviceInProgress),
        'title': 'Service In Progress',
        'description': 'Work has started at your address',
      },
      {
        'state': stateAt(AiJourneyStage.serviceCompleted),
        'title': 'Service Completed',
        'description': 'The job is finished',
      },
    ],
    if (advance != null)
      'actions': [
        {
          'label': advance.$1,
          'action': {'type': 'send_message', 'text': advance.$2},
        },
      ],
    'fallbackText':
        'Your ${AiJourneyFixtures.service} is '
        '${isDone ? 'complete' : 'under way'}',
  };
}

/// `verification_code` — display-only, as the protocol defines it.
Map<String, dynamic> journeyVerificationCodeBlock() => <String, dynamic>{
  'type': 'verification_code',
  'id': 'journey_verification_code',
  'label': 'verification code',
  'body':
      'Share this code with ${AiJourneyFixtures.providerName} when he arrives '
      'so he '
      'can start the job.',
  'code': AiJourneyFixtures.verificationCode,
  'actions': [
    {
      'label': 'Copy code',
      'variant': 'outline',
      'action': {
        'type': 'copy_text',
        'text': AiJourneyFixtures.verificationCode,
      },
    },
  ],
  'fallbackText':
      'Your completion code is ${AiJourneyFixtures.verificationCode}',
};

/// `review_request` — stars plus an optional comment.
Map<String, dynamic> journeyReviewRequestBlock() => <String, dynamic>{
  'type': 'review_request',
  'id': 'journey_review_request',
  'serviceName': 'How was your experience?',
  'commentPlaceholder': 'Leave a comment (optional)...',
  'maxRating': 5,
  'ratingRequired': true,
  'submitLabel': 'Submit Review',
  'submitTemplate': '{rating} stars: {comment}',
  'fallbackText': 'How was your ${AiJourneyFixtures.service}?',
};

/// `service_area_notice` — the address is outside coverage.
Map<String, dynamic> journeyServiceAreaNoticeBlock() => <String, dynamic>{
  'type': 'service_area_notice',
  'id': 'journey_service_area',
  'title': 'Location outside service area',
  'body': 'This address is currently outside our service area:',
  'addressText': 'Al Ruwais, Western Region, Abu Dhabi',
  'changeLabel': 'Change Location',
  'fallbackText': 'Al Ruwais is outside our service area',
};

/// `request_notice` — the booking was cancelled by the provider.
Map<String, dynamic> journeyBookingCancelledBlock() => <String, dynamic>{
  'type': 'request_notice',
  'id': 'journey_booking_cancelled',
  'requestId': AiJourneyFixtures.requestReference,
  'contextLabel': 'Booking ${AiJourneyFixtures.bookingReference}',
  'title': 'Booking cancelled',
  'body':
      '${AiJourneyFixtures.providerName} had to cancel your '
      '${AiJourneyFixtures.appointmentLabel} visit. Nothing has been charged, '
      'and I '
      'can find someone else for the same slot.',
  'status': {'label': 'Cancelled', 'tone': 'error'},
  'confirm': {
    'confirmLabel': 'Find another provider',
    'cancelLabel': 'Leave it for now',
    'confirmTemplate': 'Find me another provider for the same slot',
    'cancelTemplate': 'Leave it for now',
    'reference': AiJourneyFixtures.requestReference,
  },
  'fallbackText': 'Your booking was cancelled — shall I find someone else?',
};

/// `request_notice` — the provider is running behind.
Map<String, dynamic> journeyProviderLateBlock() => <String, dynamic>{
  'type': 'request_notice',
  'id': 'journey_provider_late',
  'requestId': AiJourneyFixtures.requestReference,
  'contextLabel': 'Booking ${AiJourneyFixtures.bookingReference}',
  'title': 'Provider running late',
  'body':
      '${AiJourneyFixtures.providerName} is about 20 minutes behind because of '
      'traffic on Sheikh Zayed Road. He is still on his way.',
  'status': {'label': 'Delayed', 'tone': 'warning'},
  'confirm': {
    'confirmLabel': 'That is fine',
    'cancelLabel': 'Reschedule',
    'confirmTemplate': 'That is fine, I will wait',
    'cancelTemplate': 'Reschedule my appointment',
    'reference': AiJourneyFixtures.requestReference,
  },
  'fallbackText':
      '${AiJourneyFixtures.providerName} is running 20 minutes late',
};

/// The offers, as contextual content rather than as a turn.
///
/// The blocks are `journeyProviderOfferBlock` at the same indices the
/// transcript uses, which means the **same node ids**. That is deliberate: the
/// conversation and the contextual surface share one `AiUiInteractionLedger`,
/// so accepting in either place marks the card answered in both and the engine
/// advances exactly once.
AiJourneyContext journeyOffersContext() => AiJourneyContext(
  id: 'journey_offers',
  peekLabel: 'You have ${AiJourneyFixtures.offerCount} new offers',
  blocks: [journeyProviderOfferBlock(), journeyProviderOfferBlock(index: 1)],
);
