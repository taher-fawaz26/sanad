import 'package:equatable/equatable.dart';

/// `CancelRequestDto` / `DisputeRequestDto` — a single required `reason`.
///
/// Shared because the client's cancel, the client's dispute and the provider's
/// cancel are the same body. The reason is shown to the other party verbatim,
/// so it is never a code or a key.
class ReasonRequest extends Equatable {
  const ReasonRequest(this.reason);

  final String reason;

  Map<String, dynamic> toJson() => {'reason': reason.trim()};

  @override
  List<Object?> get props => [reason];
}
