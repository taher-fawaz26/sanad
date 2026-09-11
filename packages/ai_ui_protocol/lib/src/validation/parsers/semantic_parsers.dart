part of 'package:ai_ui_protocol/src/validation/ai_ui_validator.dart';

/// One parser per semantic node type — the business components.
///
/// See `primitive_parsers.dart` for why these are an extension on `_Run` and a
/// `part` of the validator, and for the totality contract every method here
/// keeps.
extension _SemanticParsers on _Run {
  AiUiNode? _serviceCard(
    Map<String, dynamic> json,
    String path,
    String id,
    String? a11yLabel,
    String? fallbackText,
  ) {
    const wire = 'service_card';
    _unknownKeys(json, path, wire, const {
      'serviceId',
      'title',
      'subtitle',
      'price',
      'ratingValue',
      'image',
      'badge',
      'action',
      'selected',
      'actions',
    });

    final serviceId = _requiredString(json, 'serviceId', path, wire);
    final title = _requiredString(
      json,
      'title',
      path,
      wire,
      maxLength: limits.maxLabelLength,
    );
    if (serviceId == null || title == null) return null;

    return AiUiServiceCardNode(
      id: id,
      serviceId: serviceId,
      title: title,
      subtitle: _optionalString(
        json,
        'subtitle',
        path,
        wire,
        maxLength: limits.maxTextLength,
      ),
      price: _money(json, 'price', path, wire),
      ratingValue: _boundedDouble(json, 'ratingValue', path, wire, 0, 5),
      image: _nestedImage(json, 'image', path, wire),
      badge: _badge(json, 'badge', path, wire),
      action: json.containsKey('action')
          ? action(json['action'], '$path.action', wire)
          : null,
      selected: _bool(json, 'selected', path, wire, defaultValue: false),
      actions: _cardActions(json, path, wire),
      a11yLabel: a11yLabel,
      fallbackText: fallbackText,
    );
  }

  AiUiNode? _appointmentCard(
    Map<String, dynamic> json,
    String path,
    String id,
    String? a11yLabel,
    String? fallbackText,
  ) {
    const wire = 'appointment_card';
    _unknownKeys(json, path, wire, const {
      'appointmentId',
      'title',
      'startsAt',
      'whereText',
      'status',
      'statusTone',
      'action',
      'actions',
    });

    final appointmentId = _requiredString(json, 'appointmentId', path, wire);
    final title = _requiredString(
      json,
      'title',
      path,
      wire,
      maxLength: limits.maxLabelLength,
    );
    final startsAt = _instant(json, 'startsAt', path, wire);
    if (appointmentId == null || title == null || startsAt == null) return null;

    return AiUiAppointmentCardNode(
      id: id,
      appointmentId: appointmentId,
      title: title,
      startsAt: startsAt,
      whereText: _optionalString(
        json,
        'whereText',
        path,
        wire,
        maxLength: limits.maxTextLength,
      ),
      status: _optionalString(
        json,
        'status',
        path,
        wire,
        maxLength: limits.maxChipLabelLength,
      ),
      statusTone: _enum(
        json,
        'statusTone',
        path,
        wire,
        AiUiTone.tryFromWire,
        AiUiTone.neutral,
      ),
      action: json.containsKey('action')
          ? action(json['action'], '$path.action', wire)
          : null,
      actions: _cardActions(json, path, wire),
      a11yLabel: a11yLabel,
      fallbackText: fallbackText,
    );
  }

  AiUiNode? _branchCard(
    Map<String, dynamic> json,
    String path,
    String id,
    String? a11yLabel,
    String? fallbackText,
  ) {
    const wire = 'branch_card';
    _unknownKeys(json, path, wire, const {
      'branchId',
      'name',
      'addressText',
      'distanceMeters',
      'status',
      'statusTone',
      'action',
      'hoursText',
      'actions',
    });

    final branchId = _requiredString(json, 'branchId', path, wire);
    final name = _requiredString(
      json,
      'name',
      path,
      wire,
      maxLength: limits.maxLabelLength,
    );
    if (branchId == null || name == null) return null;

    return AiUiBranchCardNode(
      id: id,
      branchId: branchId,
      name: name,
      addressText: _optionalString(
        json,
        'addressText',
        path,
        wire,
        maxLength: limits.maxTextLength,
      ),
      distanceMeters: _boundedDouble(
        json,
        'distanceMeters',
        path,
        wire,
        0,
        40000000,
      ),
      status: _optionalString(
        json,
        'status',
        path,
        wire,
        maxLength: limits.maxChipLabelLength,
      ),
      statusTone: _enum(
        json,
        'statusTone',
        path,
        wire,
        AiUiTone.tryFromWire,
        AiUiTone.neutral,
      ),
      action: json.containsKey('action')
          ? action(json['action'], '$path.action', wire)
          : null,
      hoursText: _optionalString(
        json,
        'hoursText',
        path,
        wire,
        maxLength: limits.maxLabelLength,
      ),
      actions: _cardActions(json, path, wire),
      a11yLabel: a11yLabel,
      fallbackText: fallbackText,
    );
  }

  AiUiNode? _documentCard(
    Map<String, dynamic> json,
    String path,
    String id,
    String? a11yLabel,
    String? fallbackText,
  ) {
    const wire = 'document_card';
    _unknownKeys(json, path, wire, const {
      'documentId',
      'title',
      'status',
      'statusTone',
      'action',
      'actions',
    });

    final documentId = _requiredString(json, 'documentId', path, wire);
    final title = _requiredString(
      json,
      'title',
      path,
      wire,
      maxLength: limits.maxLabelLength,
    );
    final status = _requiredString(
      json,
      'status',
      path,
      wire,
      maxLength: limits.maxChipLabelLength,
    );
    if (documentId == null || title == null || status == null) return null;

    return AiUiDocumentCardNode(
      id: id,
      documentId: documentId,
      title: title,
      status: status,
      statusTone: _enum(
        json,
        'statusTone',
        path,
        wire,
        AiUiTone.tryFromWire,
        AiUiTone.neutral,
      ),
      action: json.containsKey('action')
          ? action(json['action'], '$path.action', wire)
          : null,
      actions: _cardActions(json, path, wire),
      a11yLabel: a11yLabel,
      fallbackText: fallbackText,
    );
  }

  AiUiNode? _quickReply(
    Map<String, dynamic> json,
    String path,
    String id,
    String? a11yLabel,
    String? fallbackText,
  ) {
    const wire = 'quick_reply';
    _unknownKeys(json, path, wire, const {'options'});

    final raw = json['options'];
    if (raw is! List) {
      add(
        AiUiDiagnosticCode.missingRequiredProperty,
        path,
        nodeType: wire,
        detail: 'options missing or not an array',
      );
      return null;
    }

    var entries = raw;
    if (entries.length > limits.maxQuickReplyOptions) {
      add(
        AiUiDiagnosticCode.limitExceeded,
        '$path.options',
        nodeType: wire,
        detail:
            '${entries.length} options > ${limits.maxQuickReplyOptions}, '
            'truncated',
      );
      entries = entries.sublist(0, limits.maxQuickReplyOptions);
    }

    final options = <AiUiQuickReplyOption>[];
    for (var i = 0; i < entries.length; i++) {
      final optionPath = '$path.options[$i]';
      final entry = entries[i];
      if (entry is! Map<String, dynamic>) {
        add(
          AiUiDiagnosticCode.invalidProperty,
          optionPath,
          nodeType: wire,
          detail: 'option is ${entry.runtimeType}, expected object',
        );
        continue;
      }
      final label = _requiredString(
        entry,
        'label',
        optionPath,
        wire,
        maxLength: limits.maxChipLabelLength,
      );
      final resolved = action(entry['action'], '$optionPath.action', wire);
      if (label == null || resolved == null) continue;
      options.add(AiUiQuickReplyOption(label: label, action: resolved));
    }

    if (options.length < limits.minQuickReplyOptions) {
      add(
        AiUiDiagnosticCode.limitExceeded,
        '$path.options',
        nodeType: wire,
        detail:
            '${options.length} valid options < '
            '${limits.minQuickReplyOptions}',
      );
      return null;
    }

    return AiUiQuickReplyNode(
      id: id,
      options: options,
      a11yLabel: a11yLabel,
      fallbackText: fallbackText,
    );
  }

  // ── Entity cards ──────────────────────────────────────────────────────────

  AiUiNode? _orderCard(
    Map<String, dynamic> json,
    String path,
    String id,
    String? a11yLabel,
    String? fallbackText,
  ) {
    const wire = 'order_card';
    _unknownKeys(json, path, wire, const {
      'orderId',
      'title',
      'statusText',
      'status',
      'statusTone',
      'amount',
      'action',
      'actions',
    });

    final orderId = _requiredString(json, 'orderId', path, wire);
    final title = _requiredString(
      json,
      'title',
      path,
      wire,
      maxLength: limits.maxLabelLength,
    );
    if (orderId == null || title == null) return null;

    return AiUiOrderCardNode(
      id: id,
      orderId: orderId,
      title: title,
      statusText: _optionalString(
        json,
        'statusText',
        path,
        wire,
        maxLength: limits.maxLabelLength,
      ),
      status: _optionalString(
        json,
        'status',
        path,
        wire,
        maxLength: limits.maxChipLabelLength,
      ),
      statusTone: _enum(
        json,
        'statusTone',
        path,
        wire,
        AiUiTone.tryFromWire,
        AiUiTone.neutral,
      ),
      amount: _money(json, 'amount', path, wire),
      action: json.containsKey('action')
          ? action(json['action'], '$path.action', wire)
          : null,
      actions: _cardActions(json, path, wire),
      a11yLabel: a11yLabel,
      fallbackText: fallbackText,
    );
  }

  AiUiNode? _providerCard(
    Map<String, dynamic> json,
    String path,
    String id,
    String? a11yLabel,
    String? fallbackText,
  ) {
    const wire = 'provider_card';
    _unknownKeys(json, path, wire, const {
      'providerId',
      'name',
      'roleText',
      'ratingValue',
      'image',
      'stats',
      'action',
      'actions',
      'verified',
      'presentation',
      'distanceMeters',
      'description',
      'services',
      'servicesLabel',
      'photos',
      'proposedTimeLabel',
      'proposedTime',
      'offer',
    });

    final providerId = _requiredString(json, 'providerId', path, wire);
    final name = _requiredString(
      json,
      'name',
      path,
      wire,
      maxLength: limits.maxLabelLength,
    );
    if (providerId == null || name == null) return null;

    return AiUiProviderCardNode(
      id: id,
      providerId: providerId,
      name: name,
      roleText: _optionalString(
        json,
        'roleText',
        path,
        wire,
        maxLength: limits.maxLabelLength,
      ),
      ratingValue: _boundedDouble(json, 'ratingValue', path, wire, 0, 5),
      image: _nestedImage(json, 'image', path, wire),
      stats: _stats(json, path, wire),
      action: json.containsKey('action')
          ? action(json['action'], '$path.action', wire)
          : null,
      actions: _cardActions(json, path, wire),
      verified: _bool(json, 'verified', path, wire, defaultValue: false),
      presentation: _enum(
        json,
        'presentation',
        path,
        wire,
        AiUiPresentation.tryFromWire,
        AiUiPresentation.compact,
      ),
      distanceMeters: _boundedDouble(
        json,
        'distanceMeters',
        path,
        wire,
        0,
        40000000,
      ),
      description: _optionalString(
        json,
        'description',
        path,
        wire,
        maxLength: limits.maxTextLength,
      ),
      services: _labelList(
        json,
        'services',
        path,
        wire,
        limits.maxServiceTags,
      ),
      servicesLabel: _optionalString(
        json,
        'servicesLabel',
        path,
        wire,
        maxLength: limits.maxLabelLength,
      ),
      photos: _imageList(json, 'photos', path, wire),
      proposedTimeLabel: _optionalString(
        json,
        'proposedTimeLabel',
        path,
        wire,
        maxLength: limits.maxLabelLength,
      ),
      // Optional, so an unparseable instant drops the row rather than the
      // card: a provider is still worth showing without a proposed time.
      proposedTime: json['proposedTime'] == null
          ? null
          : _instant(json, 'proposedTime', path, wire),
      offer: _providerOffer(json, path, wire),
      a11yLabel: a11yLabel,
      fallbackText: fallbackText,
    );
  }

  // ── Summaries ─────────────────────────────────────────────────────────────

  AiUiNode? _bookingSummary(
    Map<String, dynamic> json,
    String path,
    String id,
    String? a11yLabel,
    String? fallbackText,
  ) {
    const wire = 'booking_summary';
    _unknownKeys(json, path, wire, const {
      'title',
      'items',
      'actions',
      'statusText',
      'statusTone',
      'provider',
    });

    final items = _detailItems(json, 'items', path, wire);
    // A summary is its rows. Without them there is nothing to confirm, and a
    // header plus two buttons would ask the user to agree to nothing.
    if (items.isEmpty) {
      add(
        AiUiDiagnosticCode.missingRequiredProperty,
        '$path.items',
        nodeType: wire,
        detail: 'no valid items',
      );
      return null;
    }

    return AiUiBookingSummaryNode(
      id: id,
      items: items,
      title: _optionalString(
        json,
        'title',
        path,
        wire,
        maxLength: limits.maxLabelLength,
      ),
      actions: _cardActions(json, path, wire),
      statusText: _optionalString(
        json,
        'statusText',
        path,
        wire,
        maxLength: limits.maxLabelLength,
      ),
      statusTone: _enum(
        json,
        'statusTone',
        path,
        wire,
        AiUiTone.tryFromWire,
        AiUiTone.success,
      ),
      provider: _providerRef(json, path, wire),
      a11yLabel: a11yLabel,
      fallbackText: fallbackText,
    );
  }

  AiUiNode? _requestSummary(
    Map<String, dynamic> json,
    String path,
    String id,
    String? a11yLabel,
    String? fallbackText,
  ) {
    const wire = 'request_summary';
    _unknownKeys(json, path, wire, const {
      'items',
      'summaryTitle',
      'summaryText',
      'location',
      'actions',
      'photos',
      'photosLabel',
      'confirm',
    });

    final items = _detailItems(json, 'items', path, wire);
    if (items.isEmpty) {
      add(
        AiUiDiagnosticCode.missingRequiredProperty,
        '$path.items',
        nodeType: wire,
        detail: 'no valid items',
      );
      return null;
    }

    return AiUiRequestSummaryNode(
      id: id,
      items: items,
      summaryTitle: _optionalString(
        json,
        'summaryTitle',
        path,
        wire,
        maxLength: limits.maxLabelLength,
      ),
      summaryText: _optionalString(
        json,
        'summaryText',
        path,
        wire,
        maxLength: limits.maxTextLength,
      ),
      location: _locationRef(json, path, wire),
      actions: _cardActions(json, path, wire),
      photos: _imageList(json, 'photos', path, wire),
      photosLabel: _optionalString(
        json,
        'photosLabel',
        path,
        wire,
        maxLength: limits.maxLabelLength,
      ),
      confirm: _confirmChoice(json, path, wire, required: false),
      a11yLabel: a11yLabel,
      fallbackText: fallbackText,
    );
  }

  AiUiNode? _paymentReceipt(
    Map<String, dynamic> json,
    String path,
    String id,
    String? a11yLabel,
    String? fallbackText,
  ) {
    const wire = 'payment_receipt';
    _unknownKeys(json, path, wire, const {
      'title',
      'subtitle',
      'statusTone',
      'items',
      'total',
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

    final items = _detailItems(json, 'items', path, wire);
    // Unlike the summaries, a receipt survives with no rows: the headline plus
    // the total is still a complete, useful statement of what happened.
    return AiUiPaymentReceiptNode(
      id: id,
      title: title,
      items: items,
      subtitle: _optionalString(
        json,
        'subtitle',
        path,
        wire,
        maxLength: limits.maxLabelLength,
      ),
      statusTone: _enum(
        json,
        'statusTone',
        path,
        wire,
        AiUiTone.tryFromWire,
        AiUiTone.success,
      ),
      total: _receiptTotal(json, path, wire),
      actions: _cardActions(json, path, wire),
      a11yLabel: a11yLabel,
      fallbackText: fallbackText,
    );
  }

  // ── Status ────────────────────────────────────────────────────────────────

  AiUiNode? _providerSearch(
    Map<String, dynamic> json,
    String path,
    String id,
    String? a11yLabel,
    String? fallbackText,
  ) {
    const wire = 'provider_search';
    _unknownKeys(json, path, wire, const {
      'statusLabel',
      'title',
      'state',
      'body',
      'progress',
      'actions',
      'confirm',
    });

    final title = _requiredString(
      json,
      'title',
      path,
      wire,
      maxLength: limits.maxLabelLength,
    );
    if (title == null) return null;

    return AiUiProviderSearchNode(
      id: id,
      title: title,
      // An unknown state falls back to `searching` rather than dropping the
      // node: a card that says a search is running is still true, where no
      // card at all would leave the conversation silent about it.
      state: _enum(
        json,
        'state',
        path,
        wire,
        AiUiProviderSearchState.tryFromWire,
        AiUiProviderSearchState.searching,
      ),
      statusLabel: _optionalString(
        json,
        'statusLabel',
        path,
        wire,
        maxLength: limits.maxChipLabelLength,
      ),
      body: _optionalString(
        json,
        'body',
        path,
        wire,
        maxLength: limits.maxTextLength,
      ),
      // Clamped rather than rejected, matching the `progress` primitive: a
      // search reported as 140% complete is a backend bug, not a reason to
      // hide the fact that a search is running.
      progress: _boundedDouble(json, 'progress', path, wire, 0, 1),
      actions: _cardActions(json, path, wire),
      confirm: _confirmChoice(json, path, wire, required: false),
      a11yLabel: a11yLabel,
      fallbackText: fallbackText,
    );
  }

  AiUiNode? _serviceTimeline(
    Map<String, dynamic> json,
    String path,
    String id,
    String? a11yLabel,
    String? fallbackText,
  ) {
    const wire = 'service_timeline';
    _unknownKeys(json, path, wire, const {
      'title',
      'status',
      'statusTone',
      'items',
      'actions',
    });

    final items = _timelineItems(json, path, wire);
    // A timeline is its steps. A heading and a badge with nothing under them
    // would tell the user a job exists and nothing about where it has got to.
    if (items.isEmpty) {
      add(
        AiUiDiagnosticCode.missingRequiredProperty,
        '$path.items',
        nodeType: wire,
        detail: 'no valid items',
      );
      return null;
    }

    return AiUiServiceTimelineNode(
      id: id,
      items: items,
      title: _optionalString(
        json,
        'title',
        path,
        wire,
        maxLength: limits.maxLabelLength,
      ),
      status: _optionalString(
        json,
        'status',
        path,
        wire,
        maxLength: limits.maxChipLabelLength,
      ),
      statusTone: _enum(
        json,
        'statusTone',
        path,
        wire,
        AiUiTone.tryFromWire,
        AiUiTone.info,
      ),
      actions: _cardActions(json, path, wire),
      a11yLabel: a11yLabel,
      fallbackText: fallbackText,
    );
  }

  AiUiNode? _verificationCode(
    Map<String, dynamic> json,
    String path,
    String id,
    String? a11yLabel,
    String? fallbackText,
  ) {
    const wire = 'verification_code';
    _unknownKeys(json, path, wire, const {
      'label',
      'body',
      'code',
      'actions',
    });

    final code = _requiredString(
      json,
      'code',
      path,
      wire,
      maxLength: limits.maxVerificationCodeLength,
    );
    if (code == null) return null;

    return AiUiVerificationCodeNode(
      id: id,
      // Whitespace inside a code is never meaningful and would draw an empty
      // box, so "65 066" and "65066" are the same code.
      code: code.replaceAll(RegExp(r'\s+'), ''),
      label: _optionalString(
        json,
        'label',
        path,
        wire,
        maxLength: limits.maxChipLabelLength,
      ),
      body: _optionalString(
        json,
        'body',
        path,
        wire,
        maxLength: limits.maxTextLength,
      ),
      actions: _cardActions(json, path, wire),
      a11yLabel: a11yLabel,
      fallbackText: fallbackText,
    );
  }

  AiUiNode? _requestNotice(
    Map<String, dynamic> json,
    String path,
    String id,
    String? a11yLabel,
    String? fallbackText,
  ) {
    const wire = 'request_notice';
    _unknownKeys(json, path, wire, const {
      'title',
      'body',
      'requestId',
      'reference',
      'status',
      'contextLabel',
      'draftLabel',
      'draftText',
      'actions',
      'confirm',
    });

    final title = _requiredString(
      json,
      'title',
      path,
      wire,
      maxLength: limits.maxLabelLength,
    );
    if (title == null) return null;

    return AiUiRequestNoticeNode(
      id: id,
      title: title,
      body: _optionalString(
        json,
        'body',
        path,
        wire,
        maxLength: limits.maxTextLength,
      ),
      requestId: _optionalString(
        json,
        'requestId',
        path,
        wire,
        maxLength: limits.maxLabelLength,
      ),
      reference: _optionalString(
        json,
        'reference',
        path,
        wire,
        maxLength: limits.maxChipLabelLength,
      ),
      status: _badge(json, 'status', path, wire),
      contextLabel: _optionalString(
        json,
        'contextLabel',
        path,
        wire,
        maxLength: limits.maxTextLength,
      ),
      draftLabel: _optionalString(
        json,
        'draftLabel',
        path,
        wire,
        maxLength: limits.maxChipLabelLength,
      ),
      draftText: _optionalString(
        json,
        'draftText',
        path,
        wire,
        maxLength: limits.maxTextLength,
      ),
      actions: _cardActions(json, path, wire),
      // Optional: the already-active-request and provider-cancelled readings
      // both carry one, the third does not, and a notice with neither a
      // `confirm` nor an `actions` row is still a legitimate statement.
      confirm: _confirmChoice(json, path, wire, required: false),
      a11yLabel: a11yLabel,
      fallbackText: fallbackText,
    );
  }

  AiUiNode? _serviceAreaNotice(
    Map<String, dynamic> json,
    String path,
    String id,
    String? a11yLabel,
    String? fallbackText,
  ) {
    const wire = 'service_area_notice';
    _unknownKeys(json, path, wire, const {
      'title',
      'addressText',
      'body',
      'tone',
      'changeLabel',
      'actions',
    });

    final title = _requiredString(
      json,
      'title',
      path,
      wire,
      maxLength: limits.maxLabelLength,
    );
    // Dropped without an address rather than rendered as a bare warning: the
    // point of the card is telling the user *which* place was refused, and a
    // coverage notice that cannot name one leaves them with nothing to change.
    final addressText = _requiredString(
      json,
      'addressText',
      path,
      wire,
      maxLength: limits.maxTextLength,
    );
    if (title == null || addressText == null) return null;

    return AiUiServiceAreaNoticeNode(
      id: id,
      title: title,
      addressText: addressText,
      body: _optionalString(
        json,
        'body',
        path,
        wire,
        maxLength: limits.maxTextLength,
      ),
      tone: _enum(
        json,
        'tone',
        path,
        wire,
        AiUiTone.tryFromWire,
        AiUiTone.warning,
      ),
      changeLabel: _optionalString(
        json,
        'changeLabel',
        path,
        wire,
        maxLength: limits.maxChipLabelLength,
      ),
      actions: _cardActions(json, path, wire),
      a11yLabel: a11yLabel,
      fallbackText: fallbackText,
    );
  }
}
