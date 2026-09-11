part of 'package:ai_ui_protocol/src/validation/ai_ui_validator.dart';

/// Parsers for the semantic nodes that collect something from the user, and
/// for the ones that ask a question.
///
/// See `primitive_parsers.dart` for why these are an extension on `_Run` and a
/// `part` of the validator, and for the totality contract every method here
/// keeps.
///
/// The interactive nodes share one shape: the agent supplies a **template**
/// and the widget substitutes what the user chose or typed. The template is
/// validated as ordinary prose — there is nothing to interpret in it, only a
/// `{placeholder}` to replace — so an interactive card cannot post text the
/// agent did not author.
extension _InteractiveParsers on _Run {
  // ── Interactive ───────────────────────────────────────────────────────────

  AiUiNode? _timeSlots(
    Map<String, dynamic> json,
    String path,
    String id,
    String? a11yLabel,
    String? fallbackText,
  ) {
    const wire = 'time_slots';
    _unknownKeys(json, path, wire, const {
      'dateLabel',
      'slots',
      'selectedSlotId',
      'confirmLabel',
      'confirmTemplate',
    });

    final confirmLabel = _requiredString(
      json,
      'confirmLabel',
      path,
      wire,
      maxLength: limits.maxChipLabelLength,
    );
    final confirmTemplate = _requiredString(
      json,
      'confirmTemplate',
      path,
      wire,
      maxLength: limits.maxTextLength,
    );
    if (confirmLabel == null || confirmTemplate == null) return null;

    final slots = _slots(json, path, wire);
    // A selector with fewer than two choices is not a selection — the payload
    // wanted a `quick_reply`, and rendering one slot plus a confirm button
    // would be two taps for a decision the user does not have.
    if (slots.length < limits.minTimeSlots) {
      add(
        AiUiDiagnosticCode.limitExceeded,
        '$path.slots',
        nodeType: wire,
        detail: 'slots ${slots.length} < ${limits.minTimeSlots}',
      );
      return null;
    }

    final requested = _optionalString(json, 'selectedSlotId', path, wire);
    // An id matching no slot selects nothing rather than dropping the card:
    // the grid is still usable, the user just starts from a clean state.
    final selected = slots.any((slot) => slot.id == requested)
        ? requested
        : null;
    if (requested != null && selected == null) {
      add(
        AiUiDiagnosticCode.invalidProperty,
        path,
        nodeType: wire,
        detail: 'selectedSlotId matches no slot',
      );
    }

    return AiUiTimeSlotsNode(
      id: id,
      slots: slots,
      confirmLabel: confirmLabel,
      confirmTemplate: confirmTemplate,
      dateLabel: _optionalString(
        json,
        'dateLabel',
        path,
        wire,
        maxLength: limits.maxLabelLength,
      ),
      selectedSlotId: selected,
      a11yLabel: a11yLabel,
      fallbackText: fallbackText,
    );
  }

  AiUiNode? _reviewRequest(
    Map<String, dynamic> json,
    String path,
    String id,
    String? a11yLabel,
    String? fallbackText,
  ) {
    const wire = 'review_request';
    _unknownKeys(json, path, wire, const {
      'serviceName',
      'providerText',
      'commentPlaceholder',
      'maxCommentLength',
      'maxRating',
      'ratingRequired',
      'submitLabel',
      'submitTemplate',
    });

    final serviceName = _requiredString(
      json,
      'serviceName',
      path,
      wire,
      maxLength: limits.maxLabelLength,
    );
    final submitLabel = _requiredString(
      json,
      'submitLabel',
      path,
      wire,
      maxLength: limits.maxChipLabelLength,
    );
    final submitTemplate = _requiredString(
      json,
      'submitTemplate',
      path,
      wire,
      maxLength: limits.maxTextLength,
    );
    if (serviceName == null || submitLabel == null || submitTemplate == null) {
      return null;
    }

    return AiUiReviewRequestNode(
      id: id,
      serviceName: serviceName,
      submitLabel: submitLabel,
      submitTemplate: submitTemplate,
      providerText: _optionalString(
        json,
        'providerText',
        path,
        wire,
        maxLength: limits.maxLabelLength,
      ),
      commentPlaceholder: _optionalString(
        json,
        'commentPlaceholder',
        path,
        wire,
        maxLength: limits.maxLabelLength,
      ),
      // Clamped, not merely bounded: the agent may ask for a shorter comment
      // than the protocol allows, never a longer one.
      maxCommentLength: _boundedInt(
        json,
        'maxCommentLength',
        path,
        wire,
        1,
        limits.maxCommentLength,
      ),
      // Absent means no rating control at all, which is the card the protocol
      // has always had. A scale below two stars is not a scale, so it clamps
      // up rather than drawing a single tappable star.
      maxRating: _boundedInt(
        json,
        'maxRating',
        path,
        wire,
        2,
        limits.maxRating,
      ),
      ratingRequired: _bool(
        json,
        'ratingRequired',
        path,
        wire,
        defaultValue: false,
      ),
      a11yLabel: a11yLabel,
      fallbackText: fallbackText,
    );
  }

  AiUiNode? _locationPicker(
    Map<String, dynamic> json,
    String path,
    String id,
    String? a11yLabel,
    String? fallbackText,
  ) {
    const wire = 'location_picker';
    _unknownKeys(json, path, wire, const {
      'title',
      'searchPlaceholder',
      'useCurrentLabel',
      'savedLabel',
      'savedLocations',
      'confirmLabel',
      'confirmTemplate',
    });

    final title = _requiredString(
      json,
      'title',
      path,
      wire,
      maxLength: limits.maxLabelLength,
    );
    final confirmLabel = _requiredString(
      json,
      'confirmLabel',
      path,
      wire,
      maxLength: limits.maxChipLabelLength,
    );
    final confirmTemplate = _requiredString(
      json,
      'confirmTemplate',
      path,
      wire,
      maxLength: limits.maxTextLength,
    );
    if (title == null || confirmLabel == null || confirmTemplate == null) {
      return null;
    }

    final savedLocations = _savedLocations(json, path, wire);
    final useCurrentLabel = _optionalString(
      json,
      'useCurrentLabel',
      path,
      wire,
      maxLength: limits.maxLabelLength,
    );
    // A picker with nothing to pick is a dead end. Either offer the device's
    // location or offer a saved place — a title and a disabled button is not a
    // choice, and the conversation is a better place to ask.
    if (savedLocations.isEmpty && useCurrentLabel == null) {
      add(
        AiUiDiagnosticCode.missingRequiredProperty,
        path,
        nodeType: wire,
        detail: 'no savedLocations and no useCurrentLabel',
      );
      return null;
    }

    return AiUiLocationPickerNode(
      id: id,
      title: title,
      confirmLabel: confirmLabel,
      confirmTemplate: confirmTemplate,
      searchPlaceholder: _optionalString(
        json,
        'searchPlaceholder',
        path,
        wire,
        maxLength: limits.maxLabelLength,
      ),
      useCurrentLabel: useCurrentLabel,
      savedLabel: _optionalString(
        json,
        'savedLabel',
        path,
        wire,
        maxLength: limits.maxLabelLength,
      ),
      savedLocations: savedLocations,
      a11yLabel: a11yLabel,
      fallbackText: fallbackText,
    );
  }

  // ── Prompts ───────────────────────────────────────────────────────────────

  AiUiNode? _reminderCard(
    Map<String, dynamic> json,
    String path,
    String id,
    String? a11yLabel,
    String? fallbackText,
  ) {
    const wire = 'reminder_card';
    _unknownKeys(json, path, wire, const {
      'title',
      'subtitle',
      'body',
      'tone',
      'actions',
    });

    final title = _requiredString(
      json,
      'title',
      path,
      wire,
      maxLength: limits.maxLabelLength,
    );
    final body = _requiredString(
      json,
      'body',
      path,
      wire,
      maxLength: limits.maxTextLength,
    );
    if (title == null || body == null) return null;

    return AiUiReminderCardNode(
      id: id,
      title: title,
      body: body,
      subtitle: _optionalString(
        json,
        'subtitle',
        path,
        wire,
        maxLength: limits.maxLabelLength,
      ),
      tone: _enum(
        json,
        'tone',
        path,
        wire,
        AiUiTone.tryFromWire,
        AiUiTone.warning,
      ),
      actions: _cardActions(json, path, wire),
      a11yLabel: a11yLabel,
      fallbackText: fallbackText,
    );
  }

  AiUiNode? _mediaRequest(
    Map<String, dynamic> json,
    String path,
    String id,
    String? a11yLabel,
    String? fallbackText,
  ) {
    const wire = 'media_request';
    _unknownKeys(json, path, wire, const {
      'title',
      'body',
      'options',
      'cancelLabel',
      'actions',
    });

    final title = _requiredString(
      json,
      'title',
      path,
      wire,
      maxLength: limits.maxLabelLength,
    );
    if (title == null) return null;

    final options = _mediaOptions(json, path, wire);
    // Offering no way to supply media is the one thing this card cannot do.
    if (options.isEmpty) {
      add(
        AiUiDiagnosticCode.missingRequiredProperty,
        '$path.options',
        nodeType: wire,
        detail: 'no valid options',
      );
      return null;
    }

    return AiUiMediaRequestNode(
      id: id,
      title: title,
      options: options,
      body: _optionalString(
        json,
        'body',
        path,
        wire,
        maxLength: limits.maxTextLength,
      ),
      cancelLabel: _optionalString(
        json,
        'cancelLabel',
        path,
        wire,
        maxLength: limits.maxChipLabelLength,
      ),
      actions: _cardActions(json, path, wire),
      a11yLabel: a11yLabel,
      fallbackText: fallbackText,
    );
  }

  AiUiNode? _permissionRequest(
    Map<String, dynamic> json,
    String path,
    String id,
    String? a11yLabel,
    String? fallbackText,
  ) {
    const wire = 'permission_request';
    _unknownKeys(json, path, wire, const {
      'permission',
      'title',
      'body',
      'image',
      'allowLabel',
      'denyLabel',
      'actions',
    });

    // `permission` has no safe default: guessing would put the wrong rationale
    // in front of the wrong platform prompt, so an unrecognised capability
    // drops the card rather than asking for the camera when the agent meant
    // the microphone.
    final rawPermission = _requiredString(json, 'permission', path, wire);
    final permission = rawPermission == null
        ? null
        : AiUiPermissionKind.tryFromWire(rawPermission);
    if (permission == null) {
      if (rawPermission != null) {
        add(
          AiUiDiagnosticCode.invalidProperty,
          path,
          nodeType: wire,
          detail: 'permission unknown',
        );
      }
      return null;
    }

    final title = _requiredString(
      json,
      'title',
      path,
      wire,
      maxLength: limits.maxLabelLength,
    );
    final allowLabel = _requiredString(
      json,
      'allowLabel',
      path,
      wire,
      maxLength: limits.maxChipLabelLength,
    );
    if (title == null || allowLabel == null) return null;

    return AiUiPermissionRequestNode(
      id: id,
      permission: permission,
      title: title,
      allowLabel: allowLabel,
      body: _optionalString(
        json,
        'body',
        path,
        wire,
        maxLength: limits.maxTextLength,
      ),
      image: _nestedImage(json, 'image', path, wire),
      denyLabel: _optionalString(
        json,
        'denyLabel',
        path,
        wire,
        maxLength: limits.maxChipLabelLength,
      ),
      actions: _cardActions(json, path, wire),
      a11yLabel: a11yLabel,
      fallbackText: fallbackText,
    );
  }

  AiUiNode? _locationConfirm(
    Map<String, dynamic> json,
    String path,
    String id,
    String? a11yLabel,
    String? fallbackText,
  ) {
    const wire = 'location_confirm';
    _unknownKeys(json, path, wire, const {
      'title',
      'image',
      'addressText',
      'confirmLabel',
      'changeLabel',
      'cancelLabel',
      'actions',
    });

    final title = _requiredString(
      json,
      'title',
      path,
      wire,
      maxLength: limits.maxLabelLength,
    );
    final addressText = _requiredString(
      json,
      'addressText',
      path,
      wire,
      maxLength: limits.maxTextLength,
    );
    final confirmLabel = _requiredString(
      json,
      'confirmLabel',
      path,
      wire,
      maxLength: limits.maxChipLabelLength,
    );
    if (title == null || addressText == null || confirmLabel == null) {
      return null;
    }

    return AiUiLocationConfirmNode(
      id: id,
      title: title,
      addressText: addressText,
      confirmLabel: confirmLabel,
      image: _nestedImage(json, 'image', path, wire),
      changeLabel: _optionalString(
        json,
        'changeLabel',
        path,
        wire,
        maxLength: limits.maxChipLabelLength,
      ),
      cancelLabel: _optionalString(
        json,
        'cancelLabel',
        path,
        wire,
        maxLength: limits.maxChipLabelLength,
      ),
      actions: _cardActions(json, path, wire),
      a11yLabel: a11yLabel,
      fallbackText: fallbackText,
    );
  }

  AiUiNode? _confirmPrompt(
    Map<String, dynamic> json,
    String path,
    String id,
    String? a11yLabel,
    String? fallbackText,
  ) {
    const wire = 'confirm_prompt';
    _unknownKeys(json, path, wire, const {
      'title',
      'body',
      'subjectTitle',
      'subjectSubtitle',
      'tone',
      'confirm',
    });

    final title = _requiredString(
      json,
      'title',
      path,
      wire,
      maxLength: limits.maxLabelLength,
    );
    // Required here, unlike on `request_summary`: the controls *are* this
    // node. A question the user cannot answer is a dead end, and the
    // conversation is a better place to ask it.
    final confirm = _confirmChoice(json, path, wire, required: true);
    if (title == null || confirm == null) return null;

    return AiUiConfirmPromptNode(
      id: id,
      title: title,
      confirm: confirm,
      body: _optionalString(
        json,
        'body',
        path,
        wire,
        maxLength: limits.maxTextLength,
      ),
      subjectTitle: _optionalString(
        json,
        'subjectTitle',
        path,
        wire,
        maxLength: limits.maxLabelLength,
      ),
      subjectSubtitle: _optionalString(
        json,
        'subjectSubtitle',
        path,
        wire,
        maxLength: limits.maxLabelLength,
      ),
      tone: _enum(
        json,
        'tone',
        path,
        wire,
        AiUiTone.tryFromWire,
        AiUiTone.warning,
      ),
      a11yLabel: a11yLabel,
      fallbackText: fallbackText,
    );
  }
}
