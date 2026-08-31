import 'package:auth/src/domain/enums/user_type.dart';
import 'package:equatable/equatable.dart';

/// Parsed `MeResponseDto` (`GET /me`) — the lean, canonical "who am I / what
/// can I do" identity, distinct from the heavier business/provider profile
/// (`GET /service-provider/profile`, etc.). See `AuthRepository.getCurrentUser`.
class AuthIdentity extends Equatable {
  const AuthIdentity({
    required this.id,
    required this.email,
    required this.userType,
    required this.permissions,
    this.name,
  });

  final String id;
  final String? name;

  /// `null` for phone-registered clients — `GET /me` now omits it for them.
  final String? email;
  final UserType userType;
  final List<String> permissions;

  @override
  List<Object?> get props => [id, name, email, userType, permissions];
}
