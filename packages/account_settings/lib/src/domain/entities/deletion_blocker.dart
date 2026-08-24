import 'package:account_settings/src/domain/enums/deletion_blocker_code.dart';
import 'package:equatable/equatable.dart';

/// `DeletionBlockerDto` — a condition preventing deletion from starting.
class DeletionBlocker extends Equatable {
  const DeletionBlocker({
    required this.code,
    required this.rawCode,
    required this.message,
    this.details,
  });

  final DeletionBlockerCode code;

  /// The raw server code, preserved for [DeletionBlockerCode.unknown] so the
  /// UI can still fail safe without exposing it directly to the user.
  final String rawCode;
  final String message;
  final Map<String, dynamic>? details;

  @override
  List<Object?> get props => [code, rawCode, message, details];
}
