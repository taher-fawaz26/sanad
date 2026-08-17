import 'package:authorization/src/routing/route_rule.dart';

/// Ordered, declarative route → permission-requirement table. First match
/// wins — order rules from most to least specific, since a broad matcher
/// (e.g. a details-page regex) can otherwise shadow a more specific literal
/// route (e.g. an `/add` sibling under the same path prefix).
final class RouteAuthorizationTable {
  const RouteAuthorizationTable(this.rules);

  static const RouteAuthorizationTable empty = RouteAuthorizationTable([]);

  final List<RouteRule> rules;

  /// The first rule matching [location], or `null` if none applies — a
  /// `null` result means the route carries no permission requirement and the
  /// caller should fall through to its other guards.
  RouteRule? ruleFor(String location) {
    for (final rule in rules) {
      if (rule.matches(location)) return rule;
    }
    return null;
  }
}
