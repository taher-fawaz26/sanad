import 'package:auth/src/domain/entities/client_auth_user_entity.dart';
import 'package:auth/src/domain/enums/auth_account_status.dart';
import 'package:equatable/equatable.dart';

/// Parsed `POST auth/client/verify` response — the single result shape for
/// both first-time and returning clients (the server, not the app, decides
/// which). The client only reads [status] and [user] to choose the next step.
///
/// [accessToken]/[refreshToken] are non-null **only** when [status] is
/// [AuthAccountStatus.active]; [user] is null whenever no session was issued.
class ClientVerifyResult extends Equatable {
  const ClientVerifyResult({
    required this.status,
    this.accessToken,
    this.refreshToken,
    this.user,
  });

  final AuthAccountStatus status;
  final String? accessToken;
  final String? refreshToken;
  final ClientAuthUser? user;

  @override
  List<Object?> get props => [status, accessToken, refreshToken, user];
}
