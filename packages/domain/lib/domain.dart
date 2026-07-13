/// Sand Domain — shared business domain contracts, entities, value objects,
/// and enums. No Flutter dependency. No infrastructure details.
///
/// Apps and feature packages consume this to stay decoupled from
/// implementation specifics.
library;

// Entities
export 'src/entities/user_entity.dart';
// Enums
export 'src/enums/user_role.dart';
// Repository contracts
export 'src/repositories/auth_repository.dart';
export 'src/repositories/user_repository.dart';
// Value objects
export 'src/value_objects/email.dart';
