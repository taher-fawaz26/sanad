import 'package:device/src/domain/enums/share_status.dart';
import 'package:equatable/equatable.dart';

/// Strongly-typed result of a share operation.
class ShareResult extends Equatable {
  const ShareResult({
    required this.status,
    this.raw,
  });

  final ShareStatus status;

  /// Optional platform-provided detail string (e.g. the chosen target id).
  final String? raw;

  bool get isSuccess => status == ShareStatus.success;

  @override
  List<Object?> get props => [status, raw];
}
