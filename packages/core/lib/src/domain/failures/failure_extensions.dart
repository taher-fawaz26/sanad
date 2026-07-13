import 'package:core/src/domain/failures/failure.dart';

/// Presentation helpers — use in BlocListener / UI.
extension FailureKindX on Failure {
  bool get isTimeout => this is TimeoutFailure;
  bool get isServer => this is ServerFailure;
  bool get isUnknown => this is UnknownFailure;
  bool get isSecureConnection => this is SecureConnectionFailure;
  bool get isUnauthorized => this is UnauthorizedFailure;
  bool get isNoInternet => this is NoInternetFailure;
  bool get isCache => this is CacheFailure;
  bool get isValidation => this is ValidationFailure;
  bool get isUnverifiedUser => this is UnverifiedUserFailure;
  bool get isUnauthorizedRole => this is UnauthorizedRoleFailure;
}
