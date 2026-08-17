/// Sanad Authorization — client-side authorization infrastructure.
///
/// The single source of truth for evaluating "can the current user do X?",
/// for UI visibility, route guarding, and feature-level capability checks.
///
/// This package owns no data layer, cache, or network access — it evaluates
/// the effective permission set already carried on the auth session
/// (`package:auth`, which implements the `AuthorizationReader` port).
/// Client-side authorization is a UX layer, not a security boundary: the
/// backend remains the authority for every protected operation.
library;

export 'src/domain/permission_requirement.dart';
export 'src/domain/permission_set.dart';
export 'src/presentation/permission_builder.dart';
export 'src/presentation/permission_gate.dart';
export 'src/reader/authorization_reader.dart';
export 'src/routing/route_authorization_table.dart';
export 'src/routing/route_rule.dart';
