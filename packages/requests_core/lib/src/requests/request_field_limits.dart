/// Field limits taken verbatim from the backend DTOs, so both apps validate
/// before a round-trip instead of rendering a 400.
///
/// The server remains the authority — these only stop obviously-invalid input
/// from leaving the device, and a rejection still has to be surfaced.
abstract final class RequestFieldLimits {
  RequestFieldLimits._();

  /// `CancelRequestDto.reason` / `DisputeRequestDto.reason`.
  static const int reasonMinLength = 3;
  static const int reasonMaxLength = 1000;

  /// `CreateOfferDto.note` / `CounterOfferDto.note`.
  static const int offerNoteMaxLength = 1000;

  /// `CreateClientRequestDto.note`.
  static const int requestNoteMaxLength = 2000;

  /// `CreateClientRequestDto.addressLine`.
  static const int addressLineMaxLength = 500;

  /// `CreateClientRequestDto.mediaIds` — "maximum 5 media IDs".
  static const int maxMediaIds = 5;

  /// `GET /provider/requests?search=`.
  static const int searchMaxLength = 120;
}
