/// Identifies the account type — service provider or end-user client.
///
/// Maps to the `type` field in API responses (case-insensitive).
enum UserRole {
  /// A service-provider account (trades / professionals).
  provider('provider'),

  /// An end-user client account.
  client('client');

  const UserRole(this.wireValue);

  /// The lowercase string the API expects in the request body.
  final String wireValue;

  /// Parses a [UserRole] from its wire-value string (case-insensitive).
  static UserRole fromString(String value) {
    final normalized = value.trim().toUpperCase();
    return UserRole.values.firstWhere(
      (r) => r.wireValue.toUpperCase() == normalized,
      orElse: () => throw ArgumentError(
        'Unknown UserRole wire value: "$value". '
        'Expected one of: ${UserRole.values.map((e) => e.wireValue).toList()}.',
      ),
    );
  }
}
