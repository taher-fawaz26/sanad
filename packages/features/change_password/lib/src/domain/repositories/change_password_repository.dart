import 'package:fpdart/fpdart.dart';
import 'package:core/core.dart';

abstract class ChangePasswordRepository {
  TaskEither<Failure, void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}
