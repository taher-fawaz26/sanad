import 'package:auth/src/auth/auth_status.dart';
import 'package:flutter/foundation.dart';

enum RegistrationStatus {
  notStarted,
  inProgress,
  submitted,
  approved,
  rejected,
}

class AuthStatusNotifier extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unknown;
  RegistrationStatus _registrationStatus = RegistrationStatus.notStarted;
  String? _submittedReferenceNumber;

  AuthStatus get status => _status;
  RegistrationStatus get registrationStatus => _registrationStatus;
  String? get submittedReferenceNumber => _submittedReferenceNumber;
  bool get isProfileCompleted =>
      _registrationStatus == RegistrationStatus.approved;

  void markRegistrationSubmitted(String? referenceNumber) {
    _registrationStatus = RegistrationStatus.submitted;
    final r = referenceNumber?.trim();
    if (r != null && r.isNotEmpty) _submittedReferenceNumber = r;
    notifyListeners();
  }

  void update(
    AuthStatus newStatus, {
    RegistrationStatus? registrationStatus,
    bool? isProfileCompleted,
    String? submittedReferenceNumber,
    bool clearSubmittedReference = false,
  }) {
    if (newStatus == AuthStatus.unauthenticated) {
      _status = AuthStatus.unauthenticated;
      _registrationStatus = RegistrationStatus.notStarted;
      _submittedReferenceNumber = null;
      notifyListeners();
      return;
    }
    _status = newStatus;
    if (clearSubmittedReference) {
      _submittedReferenceNumber = null;
    } else if (submittedReferenceNumber != null &&
        submittedReferenceNumber.trim().isNotEmpty) {
      _submittedReferenceNumber = submittedReferenceNumber.trim();
    }
    if (registrationStatus != null) {
      _registrationStatus = registrationStatus;
    } else if (isProfileCompleted != null) {
      _registrationStatus = isProfileCompleted
          ? RegistrationStatus.approved
          : RegistrationStatus.inProgress;
    }
    notifyListeners();
  }
}
