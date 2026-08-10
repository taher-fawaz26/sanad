import 'package:equatable/equatable.dart';
import 'package:invitation/src/domain/entities/invitation_status.dart';
import 'package:workers/workers.dart' show WorkerType;

/// Parsed `VerifyInvitationTokenResponseDto` (`GET
/// /workers/verify-token/{token}`).
///
/// [status]/[email]/[workerType]/[providerName] are only ever present when
/// [valid] is `true` — a malformed-token or unknown-token response comes
/// back as `valid: false` with every other field absent, per the live
/// contract (no 404 on this endpoint).
class InvitationPreview extends Equatable {
  const InvitationPreview({
    required this.valid,
    this.status,
    this.email,
    this.workerType,
    this.providerName,
  });

  final bool valid;
  final InvitationStatus? status;
  final String? email;
  final WorkerType? workerType;
  final String? providerName;

  @override
  List<Object?> get props => [valid, status, email, workerType, providerName];
}
