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
    _unknownKeys(json, path, wire, const {'title', 'items', 'actions'});

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
}
