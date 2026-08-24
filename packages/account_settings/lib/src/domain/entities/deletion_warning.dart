import 'package:account_settings/src/domain/enums/deletion_warning_code.dart';
import 'package:equatable/equatable.dart';

/// `DeletionWarningDto` — a non-blocking consequence the caller should
/// confirm before starting deletion.
class DeletionWarning extends Equatable {
  const DeletionWarning({
    required this.code,
    required this.rawCode,
    required this.message,
    this.details,
  });

  final DeletionWarningCode code;

  /// The raw server code, preserved for [DeletionWarningCode.unknown] so the
  /// UI can still fail safe without exposing it directly to the user.
  final String rawCode;
  final String message;
  final Map<String, dynamic>? details;

  @override
  List<Object?> get props => [code, rawCode, message, details];
}
