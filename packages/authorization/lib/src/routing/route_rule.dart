import 'package:authorization/src/domain/permission_requirement.dart';
import 'package:equatable/equatable.dart';

/// One entry in a `RouteAuthorizationTable` — matches a location string and
/// declares the permission requirement guarding it. Deliberately Flutter- and
/// GoRouter-free: [matches] takes a plain [String] location so the table can
/// be unit-tested without a router.
final class RouteRule extends Equatable {
  const RouteRule.exact(
    Set<String> paths, {
    required this.requires,
    this.denyRedirect,
  }) : _paths = paths,
       _prefix = null,
       _pattern = null;

  const RouteRule.prefix(
    String prefix, {
    required this.requires,
    this.denyRedirect,
  }) : _paths = null,
       _prefix = prefix,
       _pattern = null;

  const RouteRule.pattern(
    RegExp pattern, {
    required this.requires,
    this.denyRedirect,
  }) : _paths = null,
       _prefix = null,
       _pattern = pattern;

  final Set<String>? _paths;
  final String? _prefix;
  final RegExp? _pattern;

  /// The permission requirement that must be satisfied to allow the matched
  /// location.
  final PermissionRequirement requires;

  /// Where to redirect when [requires] is unresolved-negative. Defaults to
  /// the caller-supplied fallback (typically the app home route) when null —
  /// this class does not hardcode an app route.
  final String? denyRedirect;

  bool matches(String location) {
    final paths = _paths;
    if (paths != null) return paths.contains(location);
    final prefix = _prefix;
    if (prefix != null) return location.startsWith(prefix);
    final pattern = _pattern;
    if (pattern != null) return pattern.hasMatch(location);
    return false;
  }

  @override
  List<Object?> get props => [
    _paths,
    _prefix,
    _pattern?.pattern,
    requires,
    denyRedirect,
  ];
}
