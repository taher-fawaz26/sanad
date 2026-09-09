import 'package:ai_ui_protocol/src/diagnostics/ai_ui_diagnostic.dart';
import 'package:ai_ui_protocol/src/domain/ai_ui_action.dart';
import 'package:ai_ui_protocol/src/domain/ai_ui_document.dart';
import 'package:ai_ui_protocol/src/domain/ai_ui_enums.dart';
import 'package:ai_ui_protocol/src/domain/ai_ui_node.dart';
import 'package:ai_ui_protocol/src/domain/ai_ui_node_type.dart';
import 'package:ai_ui_protocol/src/domain/ai_ui_values.dart';
import 'package:ai_ui_protocol/src/validation/ai_ui_codec.dart';
import 'package:ai_ui_protocol/src/validation/ai_ui_limits.dart';
import 'package:ai_ui_protocol/src/validation/ai_ui_parse_result.dart';
import 'package:ai_ui_protocol/src/validation/ai_ui_url_policy.dart';
import 'package:equatable/equatable.dart';

part 'package:ai_ui_protocol/src/validation/parsers/primitive_parsers.dart';
part 'package:ai_ui_protocol/src/validation/parsers/interactive_parsers.dart';
part 'package:ai_ui_protocol/src/validation/parsers/semantic_parsers.dart';

/// Host-specific knobs on validation behaviour.
final class AiUiValidatorOptions extends Equatable {
  const AiUiValidatorOptions({this.keepUnsupportedNodes = false});

  /// When set, a node type this client does not recognise (and which carried
  /// no `fallbackText`) survives as an [AiUiUnsupportedNode] so a developer
  /// can see what the agent sent. Callers pass `!kReleaseMode`; in release the
  /// node is dropped and users see nothing.
  final bool keepUnsupportedNodes;

  @override
  List<Object?> get props => [keepUnsupportedNodes];
}

/// Turns an untrusted AI payload into a typed, bounded, renderable document —
/// or into nothing, with an explanation.
///
/// The whole class is total: there is no input for which any public method
/// throws. That is the point. `.claude`-level rule for this feature is that a
/// malformed payload degrades the bubble, never the chat, and the cheapest way
/// to guarantee it is to make invalid states unrepresentable *before* the
/// widget layer rather than defending inside every renderer.
final class AiUiValidator {
  const AiUiValidator({
    this.limits = AiUiLimits.defaults,
    this.urlPolicy = AiUiUrlPolicy.denyAll,
    this.imageUrlPolicy = AiUiUrlPolicy.httpsAnyHost,
    this.supportedActions,
    this.knownAssetIds,
    this.options = const AiUiValidatorOptions(),
  });

  final AiUiLimits limits;

  /// Gates the `open_url` **action** — a whole web page. Deny-all by default.
  final AiUiUrlPolicy urlPolicy;

  /// Gates an `image.url`. Defaults to [AiUiUrlPolicy.httpsAnyHost]: dynamic
  /// business media lives on whatever CDN the backend uses, so an allowlist
  /// here would mean no image renders until it is configured. Pass a policy
  /// with `allowedHosts` to tighten it to specific origins.
  ///
  /// Separate from [urlPolicy] on purpose. Admitting a picture from a CDN and
  /// admitting arbitrary navigation are different decisions with different
  /// owners, and collapsing them into one field would make the safer choice
  /// impossible to express.
  final AiUiUrlPolicy imageUrlPolicy;

  /// The actions this host's registry actually implements. `null` means "the
  /// whole protocol catalog" — useful in protocol tests, wrong in an app,
  /// where it should be the registry's real key set so an action with no
  /// handler never reaches a button.
  final Set<AiUiActionType>? supportedActions;

  /// Asset ids this host publishes. `null` skips the check — the protocol
  /// package has no asset knowledge of its own.
  final Set<String>? knownAssetIds;

  final AiUiValidatorOptions options;

  /// Decode + validate in one step. The normal entry point.
  AiUiParseResult parse(String raw) {
    final decoded = AiUiCodec.decode(raw, limits: limits);
    return switch (decoded) {
      AiUiDecodeFailure(:final diagnostic) => AiUiParseResult.rejected([
        diagnostic,
      ]),
      AiUiDecodeSuccess(:final json) => validate(json),
    };
  }

  /// Validate an already-decoded payload.
  AiUiParseResult validate(Map<String, dynamic> json) {
    final run = _Run(
      limits: limits,
      urlPolicy: urlPolicy,
      imageUrlPolicy: imageUrlPolicy,
      supportedActions: supportedActions ?? AiUiActionType.all,
      knownAssetIds: knownAssetIds,
      options: options,
    );

    final rawVersion = json['schemaVersion'];
    if (rawVersion is! int) {
      run.add(
        AiUiDiagnosticCode.unsupportedSchemaVersion,
        r'$',
        detail: rawVersion == null
            ? 'schemaVersion missing'
            : 'schemaVersion is ${rawVersion.runtimeType}, expected int',
      );
      return AiUiParseResult.rejected(run.diagnostics);
    }
    if (!AiUiDocument.supportedSchemaVersions.contains(rawVersion)) {
      run.add(
        AiUiDiagnosticCode.unsupportedSchemaVersion,
        r'$',
        detail:
            'schemaVersion $rawVersion, '
            'supported ${AiUiDocument.supportedSchemaVersions.join(",")}',
      );
      return AiUiParseResult.rejected(run.diagnostics);
    }

    final rawBlocks = json['blocks'];
    if (rawBlocks is! List) {
      run.add(
        AiUiDiagnosticCode.malformedPayload,
        r'$.blocks',
        detail: rawBlocks == null
            ? 'blocks missing'
            : 'blocks is ${rawBlocks.runtimeType}, expected array',
      );
      return AiUiParseResult.rejected(run.diagnostics);
    }

    var entries = rawBlocks;
    if (entries.length > limits.maxBlocks) {
      run.add(
        AiUiDiagnosticCode.limitExceeded,
        r'$.blocks',
        detail: '${entries.length} blocks > ${limits.maxBlocks}, truncated',
      );
      entries = entries.sublist(0, limits.maxBlocks);
    }

    final blocks = <AiUiNode>[];
    for (var i = 0; i < entries.length; i++) {
      final node = run.node(entries[i], 'blocks[$i]', 1);
      if (run.aborted) return AiUiParseResult.rejected(run.diagnostics);
      if (node != null) blocks.add(node);
    }

    return AiUiParseResult(
      document: AiUiDocument(schemaVersion: rawVersion, blocks: blocks),
      diagnostics: run.diagnostics,
    );
  }
}

/// Mutable bookkeeping for one validation pass.
///
/// Split from [AiUiValidator] so the validator itself stays immutable and
/// shareable, while counters (nodes, actions, images) and the diagnostics list
/// live for exactly one payload.
class _Run {
  _Run({
    required this.limits,
    required this.urlPolicy,
    required this.imageUrlPolicy,
    required this.supportedActions,
    required this.knownAssetIds,
    required this.options,
  });

  final AiUiLimits limits;
  final AiUiUrlPolicy urlPolicy;

  /// Gates an `image.url`; separate from [urlPolicy], which gates `open_url`.
  final AiUiUrlPolicy imageUrlPolicy;
  final Set<AiUiActionType> supportedActions;
  final Set<String>? knownAssetIds;
  final AiUiValidatorOptions options;

  final List<AiUiDiagnostic> diagnostics = [];
  int nodeCount = 0;
  int actionCount = 0;
  int imageCount = 0;

  /// Set when the payload as a whole is not worth walking further.
  bool aborted = false;

  static const Set<String> _baseKeys = {
    'type',
    'id',
    'a11yLabel',
    'fallbackText',
  };

  /// Fields accepted by a future protocol version but rejected in v1, so the
  /// agent gets a clear signal rather than silent no-ops.
  static const Set<String> _reservedKeys = {'textKey', 'textArgs'};

  void add(
    AiUiDiagnosticCode code,
    String path, {
    String? nodeType,
    String? detail,
  }) {
    diagnostics.add(
      AiUiDiagnostic(
        code: code,
        path: path,
        nodeType: nodeType,
        detail: detail,
      ),
    );
  }

  // ── Node dispatch ─────────────────────────────────────────────────────────

  AiUiNode? node(Object? raw, String path, int depth) {
    if (aborted) return null;

    if (raw is! Map<String, dynamic>) {
      add(
        AiUiDiagnosticCode.malformedPayload,
        path,
        detail: 'node is ${raw.runtimeType}, expected object',
      );
      return null;
    }

    if (depth > limits.maxDepth) {
      add(
        AiUiDiagnosticCode.limitExceeded,
        path,
        detail: 'depth $depth > ${limits.maxDepth}',
      );
      return null;
    }

    nodeCount++;
    if (nodeCount > limits.maxNodes) {
      add(
        AiUiDiagnosticCode.limitExceeded,
        path,
        detail: 'node count > ${limits.maxNodes}, payload rejected',
      );
      aborted = true;
      return null;
    }

    final rawType = raw['type'];
    if (rawType is! String || rawType.isEmpty) {
      add(
        AiUiDiagnosticCode.missingRequiredProperty,
        path,
        detail: 'type missing or not a string',
      );
      return null;
    }

    for (final reserved in _reservedKeys) {
      if (raw.containsKey(reserved)) {
        add(
          AiUiDiagnosticCode.reservedProperty,
          path,
          nodeType: rawType,
          detail: '$reserved is reserved for a future schemaVersion',
        );
      }
    }

    final id = _idFor(raw, path);
    final a11yLabel = _optionalString(raw, 'a11yLabel', path, rawType);
    final fallbackText = _optionalString(raw, 'fallbackText', path, rawType);

    final type = AiUiNodeType.tryFromWire(rawType);
    if (type == null) {
      return _degrade(
        path: path,
        rawType: rawType,
        id: id,
        a11yLabel: a11yLabel,
        fallbackText: fallbackText,
      );
    }

    return switch (type) {
      AiUiNodeType.text => _text(raw, path, id, a11yLabel, fallbackText),
      AiUiNodeType.richText => _richText(
        raw,
        path,
        id,
        a11yLabel,
        fallbackText,
      ),
      AiUiNodeType.icon => _icon(raw, path, id, a11yLabel, fallbackText),
      AiUiNodeType.image => _image(raw, path, id, a11yLabel, fallbackText),
      AiUiNodeType.divider => _divider(raw, path, id, a11yLabel, fallbackText),
      AiUiNodeType.spacer => _spacer(raw, path, id, a11yLabel, fallbackText),
      AiUiNodeType.row => _row(raw, path, depth, id, a11yLabel, fallbackText),
      AiUiNodeType.column => _column(
        raw,
        path,
        depth,
        id,
        a11yLabel,
        fallbackText,
      ),
      AiUiNodeType.card => _card(raw, path, depth, id, a11yLabel, fallbackText),
      AiUiNodeType.button => _button(raw, path, id, a11yLabel, fallbackText),
      AiUiNodeType.chip => _chip(raw, path, id, a11yLabel, fallbackText),
      AiUiNodeType.list => _list(raw, path, depth, id, a11yLabel, fallbackText),
      AiUiNodeType.listItem => _listItem(
        raw,
        path,
        id,
        a11yLabel,
        fallbackText,
      ),
      AiUiNodeType.progress => _progress(
        raw,
        path,
        id,
        a11yLabel,
        fallbackText,
      ),
      AiUiNodeType.loading => _loading(raw, path, id, a11yLabel, fallbackText),
      AiUiNodeType.serviceCard => _serviceCard(
        raw,
        path,
        id,
        a11yLabel,
        fallbackText,
      ),
      AiUiNodeType.appointmentCard => _appointmentCard(
        raw,
        path,
        id,
        a11yLabel,
        fallbackText,
      ),
      AiUiNodeType.branchCard => _branchCard(
        raw,
        path,
        id,
        a11yLabel,
        fallbackText,
      ),
      AiUiNodeType.documentCard => _documentCard(
        raw,
        path,
        id,
        a11yLabel,
        fallbackText,
      ),
      AiUiNodeType.quickReply => _quickReply(
        raw,
        path,
        id,
        a11yLabel,
        fallbackText,
      ),
      AiUiNodeType.orderCard => _orderCard(
        raw,
        path,
        id,
        a11yLabel,
        fallbackText,
      ),
      AiUiNodeType.providerCard => _providerCard(
        raw,
        path,
        id,
        a11yLabel,
        fallbackText,
      ),
      AiUiNodeType.bookingSummary => _bookingSummary(
        raw,
        path,
        id,
        a11yLabel,
        fallbackText,
      ),
      AiUiNodeType.requestSummary => _requestSummary(
        raw,
        path,
        id,
        a11yLabel,
        fallbackText,
      ),
      AiUiNodeType.paymentReceipt => _paymentReceipt(
        raw,
        path,
        id,
        a11yLabel,
        fallbackText,
      ),
      AiUiNodeType.timeSlots => _timeSlots(
        raw,
        path,
        id,
        a11yLabel,
        fallbackText,
      ),
      AiUiNodeType.reviewRequest => _reviewRequest(
        raw,
        path,
        id,
        a11yLabel,
        fallbackText,
      ),
      AiUiNodeType.locationPicker => _locationPicker(
        raw,
        path,
        id,
        a11yLabel,
        fallbackText,
      ),
      AiUiNodeType.reminderCard => _reminderCard(
        raw,
        path,
        id,
        a11yLabel,
        fallbackText,
      ),
      AiUiNodeType.mediaRequest => _mediaRequest(
        raw,
        path,
        id,
        a11yLabel,
        fallbackText,
      ),
      AiUiNodeType.permissionRequest => _permissionRequest(
        raw,
        path,
        id,
        a11yLabel,
        fallbackText,
      ),
      AiUiNodeType.locationConfirm => _locationConfirm(
        raw,
        path,
        id,
        a11yLabel,
        fallbackText,
      ),
    };
  }

  /// An unrecognised node type: render its `fallbackText` as plain text,
  /// otherwise drop it (or keep a dev-only marker).
  AiUiNode? _degrade({
    required String path,
    required String rawType,
    required String id,
    required String? a11yLabel,
    required String? fallbackText,
  }) {
    add(
      AiUiDiagnosticCode.unknownNodeType,
      path,
      nodeType: rawType,
      detail: fallbackText != null ? 'using fallbackText' : 'no fallbackText',
    );

    if (fallbackText != null && fallbackText.isNotEmpty) {
      return AiUiTextNode(id: id, text: fallbackText, a11yLabel: a11yLabel);
    }
    if (options.keepUnsupportedNodes) {
      return AiUiUnsupportedNode(
        id: id,
        rawType: rawType,
        a11yLabel: a11yLabel,
      );
    }
    return null;
  }

  // ── Semantic collection helpers ───────────────────────────────────────────

  /// Parses a semantic node's attached `actions` row.
  ///
  /// An entry is dropped — not the card — when its label or action cannot be
  /// resolved, which is the `button` rule rather than the `chip` rule: these
  /// *are* buttons, and a button whose action no handler implements would be a
  /// dead control.
  List<AiUiCardAction> _cardActions(
    Map<String, dynamic> json,
    String path,
    String wire,
  ) {
    final raw = json['actions'];
    if (raw == null) return const [];
    if (raw is! List) {
      add(
        AiUiDiagnosticCode.invalidProperty,
        '$path.actions',
        nodeType: wire,
        detail: 'actions is ${raw.runtimeType}, expected array',
      );
      return const [];
    }

    var entries = raw;
    if (entries.length > limits.maxCardActions) {
      add(
        AiUiDiagnosticCode.limitExceeded,
        '$path.actions',
        nodeType: wire,
        detail: 'actions ${entries.length} > ${limits.maxCardActions}',
      );
      entries = entries.sublist(0, limits.maxCardActions);
    }

    final parsed = <AiUiCardAction>[];
    for (var i = 0; i < entries.length; i++) {
      final entryPath = '$path.actions[$i]';
      final entry = entries[i];
      if (entry is! Map<String, dynamic>) {
        add(
          AiUiDiagnosticCode.invalidProperty,
          entryPath,
          nodeType: wire,
          detail: 'action entry is ${entry.runtimeType}, expected object',
        );
        continue;
      }
      final label = _requiredString(
        entry,
        'label',
        entryPath,
        wire,
        maxLength: limits.maxChipLabelLength,
      );
      final resolved = action(entry['action'], '$entryPath.action', wire);
      if (label == null || resolved == null) continue;
      parsed.add(
        AiUiCardAction(
          label: label,
          action: resolved,
          variant: _enum(
            entry,
            'variant',
            entryPath,
            wire,
            AiUiButtonVariant.tryFromWire,
            AiUiButtonVariant.primary,
          ),
          intent: _enum(
            entry,
            'intent',
            entryPath,
            wire,
            AiUiButtonIntent.tryFromWire,
            AiUiButtonIntent.standard,
          ),
        ),
      );
    }
    return parsed;
  }

  /// Parses a summary / receipt / details card's label-and-value rows.
  ///
  /// Returns an empty list when nothing survives; the caller decides whether
  /// that drops the node. A summary with no rows says nothing, so the callers
  /// that require rows drop it.
  List<AiUiDetailItem> _detailItems(
    Map<String, dynamic> json,
    String key,
    String path,
    String wire,
  ) {
    final raw = json[key];
    if (raw == null) return const [];
    if (raw is! List) {
      add(
        AiUiDiagnosticCode.invalidProperty,
        '$path.$key',
        nodeType: wire,
        detail: '$key is ${raw.runtimeType}, expected array',
      );
      return const [];
    }

    var entries = raw;
    if (entries.length > limits.maxDetailItems) {
      add(
        AiUiDiagnosticCode.limitExceeded,
        '$path.$key',
        nodeType: wire,
        detail: '$key ${entries.length} > ${limits.maxDetailItems}',
      );
      entries = entries.sublist(0, limits.maxDetailItems);
    }

    final parsed = <AiUiDetailItem>[];
    for (var i = 0; i < entries.length; i++) {
      final entryPath = '$path.$key[$i]';
      final entry = entries[i];
      if (entry is! Map<String, dynamic>) {
        add(
          AiUiDiagnosticCode.invalidProperty,
          entryPath,
          nodeType: wire,
          detail: 'item is ${entry.runtimeType}, expected object',
        );
        continue;
      }
      final label = _requiredString(
        entry,
        'label',
        entryPath,
        wire,
        maxLength: limits.maxLabelLength,
      );
      final value = _requiredString(
        entry,
        'value',
        entryPath,
        wire,
        maxLength: limits.maxLabelLength,
      );
      if (label == null || value == null) continue;
      parsed.add(
        AiUiDetailItem(
          label: label,
          value: value,
          valueTone: _enum(
            entry,
            'valueTone',
            entryPath,
            wire,
            AiUiTone.tryFromWire,
            AiUiTone.neutral,
          ),
          isLtrValue: _bool(
            entry,
            'isLtrValue',
            entryPath,
            wire,
            defaultValue: false,
          ),
        ),
      );
    }
    return parsed;
  }

  /// A receipt's emphasised bottom line. A malformed total drops the total, not
  /// the receipt — the detail rows above it are still worth reading.
  AiUiReceiptTotal? _receiptTotal(
    Map<String, dynamic> json,
    String path,
    String wire,
  ) {
    final raw = json['total'];
    if (raw == null) return null;
    if (raw is! Map<String, dynamic>) {
      add(
        AiUiDiagnosticCode.invalidProperty,
        '$path.total',
        nodeType: wire,
        detail: 'total is ${raw.runtimeType}, expected object',
      );
      return null;
    }
    final label = _requiredString(
      raw,
      'label',
      '$path.total',
      wire,
      maxLength: limits.maxLabelLength,
    );
    final amount = _money(raw, 'amount', '$path.total', wire);
    if (label == null || amount == null) return null;
    return AiUiReceiptTotal(label: label, amount: amount);
  }

  /// A provider card's stats strip.
  List<AiUiStat> _stats(Map<String, dynamic> json, String path, String wire) {
    final raw = json['stats'];
    if (raw == null) return const [];
    if (raw is! List) {
      add(
        AiUiDiagnosticCode.invalidProperty,
        '$path.stats',
        nodeType: wire,
        detail: 'stats is ${raw.runtimeType}, expected array',
      );
      return const [];
    }

    var entries = raw;
    if (entries.length > limits.maxStats) {
      add(
        AiUiDiagnosticCode.limitExceeded,
        '$path.stats',
        nodeType: wire,
        detail: 'stats ${entries.length} > ${limits.maxStats}',
      );
      entries = entries.sublist(0, limits.maxStats);
    }

    final parsed = <AiUiStat>[];
    for (var i = 0; i < entries.length; i++) {
      final entryPath = '$path.stats[$i]';
      final entry = entries[i];
      if (entry is! Map<String, dynamic>) {
        add(
          AiUiDiagnosticCode.invalidProperty,
          entryPath,
          nodeType: wire,
          detail: 'stat is ${entry.runtimeType}, expected object',
        );
        continue;
      }
      final label = _requiredString(
        entry,
        'label',
        entryPath,
        wire,
        maxLength: limits.maxChipLabelLength,
      );
      final value = _requiredString(
        entry,
        'value',
        entryPath,
        wire,
        maxLength: limits.maxChipLabelLength,
      );
      if (label == null || value == null) continue;
      parsed.add(AiUiStat(label: label, value: value));
    }
    return parsed;
  }

  /// A `request_summary`'s maps row. Its action is optional, so an
  /// unresolvable one leaves static address text rather than removing the row —
  /// the address is still information.
  AiUiLocationRef? _locationRef(
    Map<String, dynamic> json,
    String path,
    String wire,
  ) {
    final raw = json['location'];
    if (raw == null) return null;
    if (raw is! Map<String, dynamic>) {
      add(
        AiUiDiagnosticCode.invalidProperty,
        '$path.location',
        nodeType: wire,
        detail: 'location is ${raw.runtimeType}, expected object',
      );
      return null;
    }
    final addressText = _requiredString(
      raw,
      'addressText',
      '$path.location',
      wire,
      maxLength: limits.maxLabelLength,
    );
    if (addressText == null) return null;
    return AiUiLocationRef(
      addressText: addressText,
      label: _optionalString(
        raw,
        'label',
        '$path.location',
        wire,
        maxLength: limits.maxLabelLength,
      ),
      action: raw.containsKey('action')
          ? action(raw['action'], '$path.location.action', wire)
          : null,
    );
  }

  /// A `time_slots` grid. Slot ids must be unique — a duplicate would make
  /// "which one is selected" ambiguous, so the later entry is dropped.
  List<AiUiTimeSlot> _slots(
    Map<String, dynamic> json,
    String path,
    String wire,
  ) {
    final raw = json['slots'];
    if (raw is! List) {
      add(
        AiUiDiagnosticCode.missingRequiredProperty,
        '$path.slots',
        nodeType: wire,
        detail: 'slots is ${raw.runtimeType}, expected array',
      );
      return const [];
    }

    var entries = raw;
    if (entries.length > limits.maxTimeSlots) {
      add(
        AiUiDiagnosticCode.limitExceeded,
        '$path.slots',
        nodeType: wire,
        detail: 'slots ${entries.length} > ${limits.maxTimeSlots}',
      );
      entries = entries.sublist(0, limits.maxTimeSlots);
    }

    final parsed = <AiUiTimeSlot>[];
    final seen = <String>{};
    for (var i = 0; i < entries.length; i++) {
      final entryPath = '$path.slots[$i]';
      final entry = entries[i];
      if (entry is! Map<String, dynamic>) {
        add(
          AiUiDiagnosticCode.invalidProperty,
          entryPath,
          nodeType: wire,
          detail: 'slot is ${entry.runtimeType}, expected object',
        );
        continue;
      }
      final slotId = _requiredString(entry, 'id', entryPath, wire);
      final label = _requiredString(
        entry,
        'label',
        entryPath,
        wire,
        maxLength: limits.maxChipLabelLength,
      );
      if (slotId == null || label == null) continue;
      if (!seen.add(slotId)) {
        add(
          AiUiDiagnosticCode.invalidProperty,
          entryPath,
          nodeType: wire,
          detail: 'duplicate slot id',
        );
        continue;
      }
      parsed.add(
        AiUiTimeSlot(
          id: slotId,
          label: label,
          enabled: _bool(entry, 'enabled', entryPath, wire, defaultValue: true),
        ),
      );
    }
    return parsed;
  }

  /// A `location_picker`'s saved places.
  List<AiUiSavedLocation> _savedLocations(
    Map<String, dynamic> json,
    String path,
    String wire,
  ) {
    final raw = json['savedLocations'];
    if (raw == null) return const [];
    if (raw is! List) {
      add(
        AiUiDiagnosticCode.invalidProperty,
        '$path.savedLocations',
        nodeType: wire,
        detail: 'savedLocations is ${raw.runtimeType}, expected array',
      );
      return const [];
    }

    var entries = raw;
    if (entries.length > limits.maxSavedLocations) {
      add(
        AiUiDiagnosticCode.limitExceeded,
        '$path.savedLocations',
        nodeType: wire,
        detail:
            'savedLocations ${entries.length} > '
            '${limits.maxSavedLocations}',
      );
      entries = entries.sublist(0, limits.maxSavedLocations);
    }

    final parsed = <AiUiSavedLocation>[];
    for (var i = 0; i < entries.length; i++) {
      final entryPath = '$path.savedLocations[$i]';
      final entry = entries[i];
      if (entry is! Map<String, dynamic>) {
        add(
          AiUiDiagnosticCode.invalidProperty,
          entryPath,
          nodeType: wire,
          detail: 'saved location is ${entry.runtimeType}, expected object',
        );
        continue;
      }
      final placeId = _requiredString(entry, 'id', entryPath, wire);
      final name = _requiredString(
        entry,
        'name',
        entryPath,
        wire,
        maxLength: limits.maxLabelLength,
      );
      final addressText = _requiredString(
        entry,
        'addressText',
        entryPath,
        wire,
        maxLength: limits.maxLabelLength,
      );
      if (placeId == null || name == null || addressText == null) continue;
      parsed.add(
        AiUiSavedLocation(
          id: placeId,
          name: name,
          addressText: addressText,
          icon: _optionalString(
            entry,
            'icon',
            entryPath,
            wire,
            maxLength: 120,
          ),
        ),
      );
    }
    return parsed;
  }

  /// A `media_request`'s options.
  List<AiUiMediaOption> _mediaOptions(
    Map<String, dynamic> json,
    String path,
    String wire,
  ) {
    final raw = json['options'];
    if (raw is! List) {
      add(
        AiUiDiagnosticCode.missingRequiredProperty,
        '$path.options',
        nodeType: wire,
        detail: 'options is ${raw.runtimeType}, expected array',
      );
      return const [];
    }

    var entries = raw;
    if (entries.length > limits.maxMediaOptions) {
      add(
        AiUiDiagnosticCode.limitExceeded,
        '$path.options',
        nodeType: wire,
        detail: 'options ${entries.length} > ${limits.maxMediaOptions}',
      );
      entries = entries.sublist(0, limits.maxMediaOptions);
    }

    final parsed = <AiUiMediaOption>[];
    for (var i = 0; i < entries.length; i++) {
      final entryPath = '$path.options[$i]';
      final entry = entries[i];
      if (entry is! Map<String, dynamic>) {
        add(
          AiUiDiagnosticCode.invalidProperty,
          entryPath,
          nodeType: wire,
          detail: 'option is ${entry.runtimeType}, expected object',
        );
        continue;
      }
      final label = _requiredString(
        entry,
        'label',
        entryPath,
        wire,
        maxLength: limits.maxLabelLength,
      );
      if (label == null) continue;
      parsed.add(
        AiUiMediaOption(
          label: label,
          source: _enum(
            entry,
            'source',
            entryPath,
            wire,
            AiUiMediaSource.tryFromWire,
            AiUiMediaSource.gallery,
          ),
        ),
      );
    }
    return parsed;
  }

  // ── Shared parsing helpers ────────────────────────────────────────────────

  List<AiUiNode> children(
    Map<String, dynamic> json,
    String path,
    int depth,
    AiUiNodeType type,
    String wire,
  ) {
    final raw = json['children'];
    if (raw == null) return const [];
    if (raw is! List) {
      add(
        AiUiDiagnosticCode.invalidProperty,
        '$path.children',
        nodeType: wire,
        detail: 'children is ${raw.runtimeType}, expected array',
      );
      return const [];
    }

    final limit = limits.childLimitFor(type);
    var entries = raw;
    if (entries.length > limit) {
      add(
        AiUiDiagnosticCode.limitExceeded,
        '$path.children',
        nodeType: wire,
        detail: '${entries.length} children > $limit, truncated',
      );
      entries = entries.sublist(0, limit);
    }

    final result = <AiUiNode>[];
    for (var i = 0; i < entries.length; i++) {
      final child = node(entries[i], '$path.children[$i]', depth + 1);
      if (aborted) return result;
      if (child != null) result.add(child);
    }
    return result;
  }

  AiUiAction? action(Object? raw, String path, String? nodeType) {
    if (raw is! Map<String, dynamic>) {
      add(
        AiUiDiagnosticCode.missingRequiredProperty,
        path,
        nodeType: nodeType,
        detail: raw == null
            ? 'action missing'
            : 'action is ${raw.runtimeType}, expected object',
      );
      return null;
    }

    final rawType = raw['type'];
    if (rawType is! String) {
      add(
        AiUiDiagnosticCode.missingRequiredProperty,
        path,
        nodeType: nodeType,
        detail: 'action type missing or not a string',
      );
      return null;
    }

    final type = AiUiActionType.tryFromWire(rawType);
    if (type == null || !supportedActions.contains(type)) {
      add(
        AiUiDiagnosticCode.unknownActionType,
        path,
        nodeType: nodeType,
        detail: type == null
            ? 'action "$rawType" not in protocol catalog'
            : 'action "$rawType" not implemented by this host',
      );
      return null;
    }

    actionCount++;
    if (actionCount > limits.maxActions) {
      add(
        AiUiDiagnosticCode.limitExceeded,
        path,
        nodeType: nodeType,
        detail: 'action count > ${limits.maxActions}',
      );
      return null;
    }

    final params = <String, String>{};
    final routeParams = <String, String>{};
    for (final entry in raw.entries) {
      if (entry.key == 'type') continue;
      if (entry.key == 'params') {
        final nested = entry.value;
        if (nested is Map<String, dynamic>) {
          for (final param in nested.entries) {
            final coerced = _scalar(param.value);
            if (coerced != null) routeParams[param.key] = coerced;
          }
        } else {
          add(
            AiUiDiagnosticCode.invalidProperty,
            path,
            nodeType: nodeType,
            detail: 'action params is ${nested.runtimeType}, expected object',
          );
        }
        continue;
      }
      final coerced = _scalar(entry.value);
      if (coerced == null) {
        add(
          AiUiDiagnosticCode.invalidProperty,
          path,
          nodeType: nodeType,
          detail: 'action param "${entry.key}" is not a scalar',
        );
        continue;
      }
      params[entry.key] = coerced;
    }

    for (final required in type.requiredParams) {
      final value = params[required];
      if (value == null || value.isEmpty) {
        add(
          AiUiDiagnosticCode.missingRequiredProperty,
          path,
          nodeType: nodeType,
          detail: 'action "${type.wire}" needs "$required"',
        );
        return null;
      }
    }

    if (type == AiUiActionType.openUrl) {
      final reason = urlPolicy.reject(params['url']!);
      if (reason != null) {
        add(
          AiUiDiagnosticCode.blockedUrl,
          path,
          nodeType: nodeType,
          detail: 'open_url blocked: $reason',
        );
        return null;
      }
    }

    return AiUiAction(type: type, params: params, routeParams: routeParams);
  }

  /// Reads the one canonical image object — `{url?, assetId?}` — from [json].
  ///
  /// The same code runs for every image in the protocol, which is what makes
  /// the precedence identical everywhere:
  ///
  /// 1. a `url` that passes the host's image URL policy wins, even when an
  ///    `assetId` sits beside it;
  /// 2. an absent, empty or **rejected** `url` falls through to `assetId`,
  ///    checked against the host's published catalog;
  /// 3. neither usable yields `null`, and the owning node shows its no-image
  ///    state (for the `image` primitive, whose whole purpose is the picture,
  ///    that means the node is dropped).
  ///
  /// Falling *through* a rejected URL rather than failing on it is deliberate:
  /// `{"url": "http://…", "assetId": "empty_state"}` should show the
  /// illustration the backend attached as a fallback, not a hole. Every
  /// rejection still records a diagnostic, so a misconfigured host or a bad
  /// URL is visible rather than merely silent.
  ///
  /// `assetId` is never a path. It is matched against [knownAssetIds] — the
  /// ids the host publishes — so a Flutter asset path, a package path, an
  /// Android/iOS resource name or an invented filename resolves to nothing.
  AiUiImageSource? imageSource(
    Map<String, dynamic> json,
    String path,
    String wire,
  ) {
    final url = _imageUrl(json, path, wire);
    final assetId = _imageAssetId(json, path, wire);

    if (url == null && assetId == null) {
      // Neither half survived. Only say so when the agent supplied nothing to
      // begin with — an explicit `null` counts as nothing, while a value that
      // was *rejected* has already produced its own, more specific diagnostic.
      if (json['url'] == null && json['assetId'] == null) {
        add(
          AiUiDiagnosticCode.missingRequiredProperty,
          path,
          nodeType: wire,
          detail: 'image needs a url or an assetId',
        );
      }
      return null;
    }

    return _countedImage(
      AiUiImageSource(url: url, assetId: assetId),
      path,
      wire,
    );
  }

  /// The `url` half: absent, empty, wrong type or policy-rejected all yield
  /// `null` so the caller can fall through to the asset.
  String? _imageUrl(Map<String, dynamic> json, String path, String wire) {
    final raw = json['url'];
    if (raw == null) return null;
    if (raw is! String) {
      add(
        AiUiDiagnosticCode.invalidProperty,
        '$path.url',
        nodeType: wire,
        detail: 'url is ${raw.runtimeType}, expected string',
      );
      return null;
    }
    // An empty string is "no url", not a broken one: it is how a backend
    // template says "I had nothing to put here" without dropping the key.
    if (raw.isEmpty) return null;

    final rejection = imageUrlPolicy.reject(raw);
    if (rejection != null) {
      // The reason never contains the URL itself — an AI-supplied URL can
      // carry tracking identifiers, and diagnostics are logged.
      add(
        AiUiDiagnosticCode.invalidProperty,
        '$path.url',
        nodeType: wire,
        detail: 'image url refused: $rejection',
      );
      return null;
    }
    return raw.trim();
  }

  /// The `assetId` half: only an id this host publishes survives.
  String? _imageAssetId(Map<String, dynamic> json, String path, String wire) {
    final raw = json['assetId'];
    if (raw == null) return null;
    if (raw is! String) {
      add(
        AiUiDiagnosticCode.invalidProperty,
        '$path.assetId',
        nodeType: wire,
        detail: 'assetId is ${raw.runtimeType}, expected string',
      );
      return null;
    }
    if (raw.isEmpty) return null;

    final known = knownAssetIds;
    if (known != null && !known.contains(raw)) {
      add(
        AiUiDiagnosticCode.unknownAssetId,
        path,
        nodeType: wire,
        detail: 'assetId "$raw" not published by this host',
      );
      return null;
    }
    return raw;
  }

  AiUiImageSource? _countedImage(
    AiUiImageSource source,
    String path,
    String wire,
  ) {
    imageCount++;
    if (imageCount > limits.maxImages) {
      add(
        AiUiDiagnosticCode.limitExceeded,
        path,
        nodeType: wire,
        detail: 'image count > ${limits.maxImages}',
      );
      return null;
    }
    return source;
  }

  AiUiImageSource? _nestedImage(
    Map<String, dynamic> json,
    String key,
    String path,
    String wire,
  ) {
    final raw = json[key];
    if (raw == null) return null;
    if (raw is! Map<String, dynamic>) {
      add(
        AiUiDiagnosticCode.invalidProperty,
        '$path.$key',
        nodeType: wire,
        detail: '$key is ${raw.runtimeType}, expected object',
      );
      return null;
    }
    return imageSource(raw, '$path.$key', wire);
  }

  AiUiBadge? _badge(
    Map<String, dynamic> json,
    String key,
    String path,
    String wire,
  ) {
    final raw = json[key];
    if (raw == null) return null;
    if (raw is! Map<String, dynamic>) {
      add(
        AiUiDiagnosticCode.invalidProperty,
        '$path.$key',
        nodeType: wire,
        detail: '$key is ${raw.runtimeType}, expected object',
      );
      return null;
    }
    final label = _requiredString(
      raw,
      'label',
      '$path.$key',
      wire,
      maxLength: limits.maxChipLabelLength,
    );
    if (label == null) return null;
    return AiUiBadge(
      label: label,
      tone: _enum(
        raw,
        'tone',
        '$path.$key',
        wire,
        AiUiTone.tryFromWire,
        AiUiTone.neutral,
      ),
    );
  }

  AiUiMoney? _money(
    Map<String, dynamic> json,
    String key,
    String path,
    String wire,
  ) {
    final raw = json[key];
    if (raw == null) return null;
    if (raw is! Map<String, dynamic>) {
      add(
        AiUiDiagnosticCode.invalidProperty,
        '$path.$key',
        nodeType: wire,
        detail: '$key is ${raw.runtimeType}, expected object',
      );
      return null;
    }
    final amount = raw['amount'];
    final currency = raw['currency'];
    if (amount is! num) {
      add(
        AiUiDiagnosticCode.invalidProperty,
        '$path.$key',
        nodeType: wire,
        detail: 'amount is ${amount.runtimeType}, expected number',
      );
      return null;
    }
    if (currency is! String || currency.trim().length != 3) {
      add(
        AiUiDiagnosticCode.invalidProperty,
        '$path.$key',
        nodeType: wire,
        detail: 'currency must be a 3-letter ISO-4217 code',
      );
      return null;
    }
    return AiUiMoney(amount: amount, currency: currency.trim().toUpperCase());
  }

  DateTime? _instant(
    Map<String, dynamic> json,
    String key,
    String path,
    String wire,
  ) {
    final raw = json[key];
    if (raw is! String || raw.isEmpty) {
      add(
        AiUiDiagnosticCode.missingRequiredProperty,
        path,
        nodeType: wire,
        detail: '$key missing or not a string',
      );
      return null;
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      add(
        AiUiDiagnosticCode.invalidProperty,
        path,
        nodeType: wire,
        detail: '$key is not a valid ISO-8601 instant',
      );
      return null;
    }
    return parsed.toUtc();
  }

  String _idFor(Map<String, dynamic> json, String path) {
    final raw = json['id'];
    if (raw is String && raw.isNotEmpty) return raw;
    return path;
  }

  String? _requiredString(
    Map<String, dynamic> json,
    String key,
    String path,
    String wire, {
    int? maxLength,
  }) {
    final raw = json[key];
    if (raw is! String || raw.trim().isEmpty) {
      add(
        AiUiDiagnosticCode.missingRequiredProperty,
        path,
        nodeType: wire,
        detail: raw == null
            ? '$key missing'
            : '$key is ${raw.runtimeType}, expected non-empty string',
      );
      return null;
    }
    return _truncate(raw, key, path, wire, maxLength);
  }

  String? _optionalString(
    Map<String, dynamic> json,
    String key,
    String path,
    String? wire, {
    int? maxLength,
  }) {
    final raw = json[key];
    if (raw == null) return null;
    if (raw is! String) {
      add(
        AiUiDiagnosticCode.invalidProperty,
        path,
        nodeType: wire,
        detail: '$key is ${raw.runtimeType}, expected string',
      );
      return null;
    }
    if (raw.isEmpty) return null;
    return _truncate(raw, key, path, wire, maxLength);
  }

  String _truncate(
    String value,
    String key,
    String path,
    String? wire,
    int? maxLength,
  ) {
    if (maxLength == null || value.length <= maxLength) return value;
    add(
      AiUiDiagnosticCode.limitExceeded,
      path,
      nodeType: wire,
      detail: '$key ${value.length} chars > $maxLength, truncated',
    );
    return value.substring(0, maxLength);
  }

  bool _bool(
    Map<String, dynamic> json,
    String key,
    String path,
    String wire, {
    required bool defaultValue,
  }) {
    final raw = json[key];
    if (raw == null) return defaultValue;
    if (raw is bool) return raw;
    add(
      AiUiDiagnosticCode.invalidProperty,
      path,
      nodeType: wire,
      detail: '$key is ${raw.runtimeType}, expected bool',
    );
    return defaultValue;
  }

  int? _boundedInt(
    Map<String, dynamic> json,
    String key,
    String path,
    String wire,
    int min,
    int max,
  ) {
    final raw = json[key];
    if (raw == null) return null;
    if (raw is! int) {
      add(
        AiUiDiagnosticCode.invalidProperty,
        path,
        nodeType: wire,
        detail: '$key is ${raw.runtimeType}, expected int',
      );
      return null;
    }
    if (raw < min || raw > max) {
      add(
        AiUiDiagnosticCode.limitExceeded,
        path,
        nodeType: wire,
        detail: '$key $raw outside $min..$max, clamped',
      );
      return raw.clamp(min, max);
    }
    return raw;
  }

  double? _boundedDouble(
    Map<String, dynamic> json,
    String key,
    String path,
    String wire,
    double min,
    double max,
  ) {
    final raw = json[key];
    if (raw == null) return null;
    if (raw is! num) {
      add(
        AiUiDiagnosticCode.invalidProperty,
        path,
        nodeType: wire,
        detail: '$key is ${raw.runtimeType}, expected number',
      );
      return null;
    }
    return raw.toDouble().clamp(min, max);
  }

  T _enum<T>(
    Map<String, dynamic> json,
    String key,
    String path,
    String wire,
    T? Function(String) tryFromWire,
    T fallback,
  ) {
    final raw = json[key];
    if (raw == null) return fallback;
    if (raw is! String) {
      add(
        AiUiDiagnosticCode.invalidProperty,
        path,
        nodeType: wire,
        detail: '$key is ${raw.runtimeType}, expected string',
      );
      return fallback;
    }
    final parsed = tryFromWire(raw);
    if (parsed == null) {
      add(
        AiUiDiagnosticCode.invalidProperty,
        path,
        nodeType: wire,
        detail: '$key "$raw" unknown, using default',
      );
      return fallback;
    }
    return parsed;
  }

  void _unknownKeys(
    Map<String, dynamic> json,
    String path,
    String wire,
    Set<String> allowed,
  ) {
    for (final key in json.keys) {
      if (_baseKeys.contains(key)) continue;
      if (allowed.contains(key)) continue;
      if (_reservedKeys.contains(key)) continue;
      add(
        AiUiDiagnosticCode.invalidProperty,
        path,
        nodeType: wire,
        detail: 'unknown property "$key" ignored',
      );
    }
  }

  static String? _scalar(Object? value) => switch (value) {
    final String s => s,
    final num n => '$n',
    final bool b => '$b',
    _ => null,
  };
}
