class LocationPickerLabels {
  const LocationPickerLabels({
    required this.searchHint,
    required this.confirm,
    required this.specifiedLocation,
    required this.addressHint,
    required this.permissionDenied,
    required this.permissionPermanentlyDenied,
    required this.serviceDisabled,
    required this.genericError,
    required this.openSettings,
    this.title,
    this.subtitle,
  });

  /// Optional sheet header title (e.g. "Branch location").
  final String? title;

  /// Optional sheet header subtitle (e.g. "Move the pin to locate…").
  final String? subtitle;

  final String searchHint;
  final String confirm;
  final String specifiedLocation;
  final String addressHint;
  final String permissionDenied;
  final String permissionPermanentlyDenied;
  final String serviceDisabled;
  final String genericError;
  final String openSettings;
}
