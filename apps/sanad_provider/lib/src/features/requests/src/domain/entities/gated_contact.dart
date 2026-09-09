import 'package:equatable/equatable.dart';

/// The client's contact details, withheld until this provider wins the work.
///
/// **[isUnlocked] is the single source of truth for visibility.** Nothing may
/// infer it from the request status, from the offer status, or from whether the
/// other fields happen to be populated — the server decides, and every other
/// field is `null` while it is `false`.
///
/// Inferring it any other way is how a matched-but-not-booked provider ends up
/// shown a client's phone number.
class GatedContact extends Equatable {
  /// Creates a contact block.
  const GatedContact({
    required this.isUnlocked,
    this.clientName,
    this.clientPhone,
    this.addressLine,
    this.lat,
    this.lng,
  });

  /// A locked block — everything withheld.
  static const GatedContact locked = GatedContact(isUnlocked: false);

  /// True once this provider's offer was accepted.
  final bool isUnlocked;

  /// The client's name. Null while locked.
  final String? clientName;

  /// The client's phone. Null while locked. Inherently LTR — render it
  /// through the design system's LTR-isolating affordances under an RTL
  /// locale.
  final String? clientPhone;

  /// The street address. Null while locked; only `areaName` is public before.
  final String? addressLine;

  /// Exact latitude. Null while locked.
  final double? lat;

  /// Exact longitude. Null while locked.
  final double? lng;

  /// Whether there is a map location to open.
  bool get hasCoordinates => isUnlocked && lat != null && lng != null;

  @override
  List<Object?> get props => [
    isUnlocked,
    clientName,
    clientPhone,
    addressLine,
    lat,
    lng,
  ];
}
