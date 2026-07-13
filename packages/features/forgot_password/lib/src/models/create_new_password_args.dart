import 'package:equatable/equatable.dart';

/// GoRouter `extra` for [CreateNewPasswordPage].
class CreateNewPasswordArgs extends Equatable {
  const CreateNewPasswordArgs({required this.identifier});

  final String identifier;

  @override
  List<Object?> get props => [identifier];
}
