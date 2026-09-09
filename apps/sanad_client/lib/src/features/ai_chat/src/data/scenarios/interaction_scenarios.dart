import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/scenarios/scenario_support.dart';

/// What the mock agent says *after* the user answers a card.
///
/// The point of this file is not the copy — it is that every reply below is
/// built by reading the [AiUiInteraction], never the sentence that travelled
/// beside it. A continuation that names the chosen slot's id, or branches on a
/// permission outcome, can only be produced if the structured result actually
/// carried those values. That makes these scenarios the proof that the loop is
/// bidirectional rather than a demo of it.
///
/// The real agent will do something considerably more interesting with the
/// same input. What it must not have to do is re-parse its own prose.
List<AiChatEvent> interactionContinuation(
  String messageId,
  AiUiInteraction interaction,
) {
  if (interaction.status == AiUiInteractionStatus.cancelled) {
    return _cancelled(messageId, interaction);
  }

  return switch (interaction.kind) {
    AiUiInteractionKind.slotSelected => _slotSelected(messageId, interaction),
    AiUiInteractionKind.reviewSubmitted => _reviewSubmitted(
      messageId,
      interaction,
    ),
    AiUiInteractionKind.locationSelected ||
    AiUiInteractionKind.locationConfirmed => _locationSelected(
      messageId,
      interaction,
    ),
    AiUiInteractionKind.permissionResult => _permissionResult(
      messageId,
      interaction,
    ),
    AiUiInteractionKind.mediaResult => _mediaResult(messageId, interaction),
    AiUiInteractionKind.quickReplySelected => scenarioSay(
      messageId,
      'Got it — ${_label(interaction)}. Let me take care of that.',
    ),
  };
}

/// A confirmed booking, followed by a card summarising it.
///
/// Reads the slot's **id** rather than its label: an agent that can only match
/// on display text would have to guess here, and the summary below is only
/// correct because the id travelled.
List<AiChatEvent> _slotSelected(
  String messageId,
  AiUiInteraction interaction,
) {
  final label = _label(interaction);
  final id = interaction.value is AiUiSelectionValue
      ? (interaction.value as AiUiSelectionValue).id ?? 'unknown'
      : 'unknown';

  return [
    scenarioStart(messageId),
    ...scenarioStream(
      messageId,
      'Perfect — $label it is. I have held that slot for you.',
    ),
    scenarioEnd(
      messageId,
      'Perfect — $label it is. I have held that slot for you.',
    ),
    scenarioUi(messageId, {
      'schemaVersion': 1,
      'blocks': [
        {
          'type': 'booking_summary',
          'id': 'summary_$id',
          'title': 'Booking confirmed',
          'items': [
            {'label': 'Service', 'value': 'AC Maintenance'},
            {'label': 'Time', 'value': label},
            {'label': 'Reference', 'value': id, 'valueTone': 'primary'},
          ],
        },
      ],
    }),
  ];
}

/// Thanks the user and echoes the comment, or notes that they left none.
List<AiChatEvent> _reviewSubmitted(
  String messageId,
  AiUiInteraction interaction,
) {
  final comment = interaction.value is AiUiTextValue
      ? (interaction.value as AiUiTextValue).text
      : '';

  final text = comment.isEmpty
      // An empty review is a real answer, and the agent is told so rather than
      // left waiting — so it can move on instead of asking again.
      ? 'Thanks for rating it. I have logged the visit without a comment.'
      : 'Thank you — I have recorded your review: "$comment".';

  return scenarioSay(messageId, text);
}

/// Branches on where the place came from, which only a structured result can
/// tell it: a saved place resolves by id, free text has to be looked up.
List<AiChatEvent> _locationSelected(
  String messageId,
  AiUiInteraction interaction,
) {
  final value = interaction.value;
  if (value is! AiUiLocationValue) {
    return scenarioSay(messageId, 'Got it. Let me look around there.');
  }

  final text = switch (value.source) {
    AiUiLocationSource.saved =>
      'Using your saved place "${value.name}"'
          '${value.addressText == null ? '' : ' (${value.addressText})'}. '
          'Here is what is nearby.',
    AiUiLocationSource.typed =>
      'Looking around "${value.name}". Here is what I found.',
  };

  return [
    scenarioStart(messageId),
    ...scenarioStream(messageId, text),
    scenarioEnd(messageId, text),
    scenarioUi(messageId, {
      'schemaVersion': 1,
      'blocks': [
        {
          'type': 'branch_card',
          'id': 'branch_near',
          'name': 'CleanCo — ${value.name}',
          'addressText': value.addressText ?? value.name,
          'hoursText': 'Open until 8:00 PM',
        },
      ],
    }),
  ];
}

/// Four different continuations for four different outcomes.
///
/// This is the case that did not exist before results: a permission prompt
/// used to end in a snackbar the agent never heard about, so it could only
/// carry on as if the answer had been yes.
List<AiChatEvent> _permissionResult(
  String messageId,
  AiUiInteraction interaction,
) {
  final value = interaction.value;
  if (value is! AiUiPermissionValue) {
    return scenarioSay(messageId, 'Understood.');
  }

  final capability = value.permission;
  final text = switch (value.outcome) {
    AiUiPermissionOutcome.granted =>
      'Thanks — I can use your $capability now. Give me a moment.',
    AiUiPermissionOutcome.denied =>
      'No problem, I will carry on without $capability access. '
          'You can tell me the details instead.',
    AiUiPermissionOutcome.permanentlyDenied =>
      'Understood — $capability is blocked in your settings. '
          'We can do this the manual way instead.',
    AiUiPermissionOutcome.unavailable =>
      'It looks like $capability is not available on this device. '
          'Tell me and I will take it from there.',
    AiUiPermissionOutcome.cancelled =>
      'That is fine — let me know if you change your mind about $capability.',
  };

  return scenarioSay(messageId, text);
}

List<AiChatEvent> _mediaResult(
  String messageId,
  AiUiInteraction interaction,
) {
  final count = interaction.value is AiUiMediaValue
      ? (interaction.value as AiUiMediaValue).count
      : 0;

  return scenarioSay(
    messageId,
    count == 0
        ? 'No photo then — describe it to me and I will work from that.'
        : 'Got $count file${count == 1 ? '' : 's'}. Let me take a look.',
  );
}

/// Every cancellation, whatever it cancelled.
///
/// One handler because the agent's job is the same in all of them: acknowledge
/// and offer the way forward. What it must never do is keep waiting for an
/// answer that has already been declined.
List<AiChatEvent> _cancelled(
  String messageId,
  AiUiInteraction interaction,
) {
  if (interaction.kind == AiUiInteractionKind.permissionResult) {
    return _permissionResult(messageId, interaction);
  }

  return scenarioSay(
    messageId,
    'No problem — we can come back to that later. '
    'Is there anything else I can help with?',
  );
}

String _label(AiUiInteraction interaction) {
  final value = interaction.value;
  return value is AiUiSelectionValue ? value.label : 'that';
}
