import 'package:auth/src/domain/entities/user_entity.dart';
import 'package:equatable/equatable.dart';

class LoginResponseEntity extends Equatable {
  const LoginResponseEntity({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final UserEntity user;

  @override
  List<Object?> get props => [accessToken, refreshToken, user];
}
