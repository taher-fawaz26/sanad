import 'package:core/core.dart';
import 'package:equatable/equatable.dart';

/// State for the post-authentication setup flow (Enter Name → Get Notified).
///
/// [status] tracks the `PATCH clients/me` submission that saves the display
/// name; [name] is the last submitted value (preserved across a failed save so
/// the user can retry without re-typing).
class AccountSetupState extends Equatable {
  /// Creates an [AccountSetupState].
  const AccountSetupState({
    this.name,
    this.status = RequestStatus.initial,
    this.failure,
  });

  /// The name entered on the Enter Name screen, or `null` before that step.
  final String? name;

  /// Lifecycle of the `PATCH clients/me` name save.
  final RequestStatus status;

  /// The failure from the last save attempt, if any.
  final Failure? failure;

  /// Returns a copy with the given fields replaced. [clearFailure] wipes
  /// [failure] (used when a new attempt starts).
  AccountSetupState copyWith({
    String? name,
    RequestStatus? status,
    Failure? failure,
    bool clearFailure = false,
  }) => AccountSetupState(
    name: name ?? this.name,
    status: status ?? this.status,
    failure: clearFailure ? null : (failure ?? this.failure),
  );

  @override
  List<Object?> get props => [name, status, failure];
}
