import 'package:equatable/equatable.dart';

/// The closed catalog of actions an AI payload may *request*.
///
/// The agent expresses intent; the application owns execution. There is no way
/// to express a callback, a method name, a Dart expression, a raw route path or
/// a raw deep link — those are not representable in this type, which is what
/// makes "AI cannot invoke arbitrary app code" a structural property rather
/// than a policy.
enum AiUiActionType {
  /// Post [AiUiAction.text] back into the conversation as a user turn. This is
  /// how `quick_reply` works.
  sendMessage('send_message', requiredParams: {'text'}),
  openService('open_service', requiredParams: {'serviceId'}),
  openAppointment('open_appointment', requiredParams: {'appointmentId'}),
  openBranch('open_branch', requiredParams: {'branchId'}),
  openDocument('open_document', requiredParams: {'documentId'}),

  /// Navigate to a *symbolic* route key that the app resolves through a
  /// compile-time map. Never a path — the agent cannot name a destination the
  /// app has not explicitly published.
  openRoute('open_route', requiredParams: {'routeKey'}),

  /// Open an external URL. Gated by `AiUiUrlPolicy` (https + host allowlist)
  /// during validation, so a blocked URL never reaches a widget.
  openUrl('open_url', requiredParams: {'url'}),
  copyText('copy_text', requiredParams: {'text'}),

  /// Asks the app to run its own location-sharing flow.
  ///
  /// The agent gets no device access from this action: it states an intent,
  /// and the app owns the permission prompt, the lookup, and whether to
  /// proceed at all. Emitted by the live agent as a `button` action.
  requestLocationShare('request_location_share', requiredParams: {}),

  /// Asks the app to run its own image picker / upload flow.
  ///
  /// Same contract as [requestLocationShare] — no filesystem or camera access
  /// is granted to the agent. Emitted by the live agent as a `button` action.
  requestImageUpload('request_image_upload', requiredParams: {}),

  dismiss('dismiss', requiredParams: {})
  ;

  const AiUiActionType(this.wire, {required this.requiredParams});

  /// The exact JSON `type` string the agent must send.
  final String wire;

  /// Params that must be present and non-empty for the action to be valid.
  final Set<String> requiredParams;

  static AiUiActionType? tryFromWire(String value) {
    for (final candidate in values) {
      if (candidate.wire == value) return candidate;
    }
    return null;
  }

  /// Every action the protocol defines. A host narrows this to the set its
  /// action registry actually implements when constructing the validator.
  static Set<AiUiActionType> get all => values.toSet();
}

/// A declarative, inert action request.
///
/// [params] holds only scalar values coerced to `String`. Nested structures are
/// not representable except for [routeParams], which carries `open_route`'s
/// bounded `params` object.
final class AiUiAction extends Equatable {
  const AiUiAction({
    required this.type,
    this.params = const {},
    this.routeParams = const {},
  });

  final AiUiActionType type;
  final Map<String, String> params;
  final Map<String, String> routeParams;

  String? get text => params['text'];
  String? get serviceId => params['serviceId'];
  String? get appointmentId => params['appointmentId'];
  String? get branchId => params['branchId'];
  String? get documentId => params['documentId'];
  String? get routeKey => params['routeKey'];
  String? get url => params['url'];

  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': type.wire,
    ...params,
    if (routeParams.isNotEmpty) 'params': Map<String, String>.of(routeParams),
  };

  @override
  List<Object?> get props => [type, params, routeParams];
}
