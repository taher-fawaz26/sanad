sealed class SecureTransportException implements Exception {
  const SecureTransportException(this.message);
  final String message;

  String get typeName;

  @override
  String toString() => '$typeName: $message';
}

class TlsPinningRejectedException extends SecureTransportException {
  const TlsPinningRejectedException([
    super.message = 'Secure connection failed',
  ]);

  @override
  String get typeName => 'TlsPinningRejectedException';
}

class CertificateValidationFailedException extends SecureTransportException {
  const CertificateValidationFailedException([
    super.message = 'Certificate validation failed',
  ]);

  @override
  String get typeName => 'CertificateValidationFailedException';
}

class UnexpectedTransportSecurityException extends SecureTransportException {
  const UnexpectedTransportSecurityException(super.message);

  @override
  String get typeName => 'UnexpectedTransportSecurityException';
}
