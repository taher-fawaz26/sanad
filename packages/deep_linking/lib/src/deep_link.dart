import 'package:meta/meta.dart';

/// A validated incoming deep link, reduced to a router-navigable location.
@immutable
class DeepLink {
  /// Creates a [DeepLink] from its source [uri] and resolved [location].
  const DeepLink({required this.uri, required this.location});

  /// The original incoming URI,
  /// e.g. `https://links.trysanad.us/invitation/abc123`.
  final Uri uri;

  /// The GoRouter-navigable location derived from [uri] (path + query),
  /// e.g. `/invitation/abc123`.
  final String location;

  @override
  bool operator ==(Object other) =>
      other is DeepLink && other.uri == uri && other.location == location;

  @override
  int get hashCode => Object.hash(uri, location);

  @override
  String toString() => 'DeepLink(location: $location)';
}
