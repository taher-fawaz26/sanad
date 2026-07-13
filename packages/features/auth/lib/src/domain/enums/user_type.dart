/// Identifies whether a user account represents a service provider or a client.
///
/// [value] is the **lowercase** string the live API expects in
/// `POST /auth/register`. Responses and JWTs may use any casing;
/// [fromString] normalizes case-insensitively.
enum UserType {
  provider('provider'),
  client('client');

  const UserType(this.value);

  final String value;

  static UserType fromString(String value) {
    final normalized = value.trim().toUpperCase();
    return UserType.values.firstWhere(
      (type) => type.value.toUpperCase() == normalized,
      orElse: () => throw ArgumentError(
        'Unknown UserType wire value: "$value". '
        'Expected one of '
        '${UserType.values.map((e) => e.value.toUpperCase()).toList()} '
        '(case-insensitive).',
      ),
    );
  }
}
