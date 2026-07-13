import 'package:domain/domain.dart';

/// Fake user entities for use in tests.
abstract final class FakeUserEntity {
  /// A verified client user entity for use in tests.
  static const UserEntity client = UserEntity(
    sub: 'client-sub-123',
    identifier: '+966500000001',
    identifierType: 'phone',
    isVerified: true,
    isProfileCompleted: true,
    role: UserRole.client,
  );

  /// A verified provider user entity for use in tests.
  static const UserEntity provider = UserEntity(
    sub: 'provider-sub-456',
    identifier: '+966500000002',
    identifierType: 'phone',
    isVerified: true,
    isProfileCompleted: true,
    role: UserRole.provider,
  );

  /// An unverified client user entity for use in tests.
  static const UserEntity unverifiedClient = UserEntity(
    sub: 'client-unverified-789',
    identifier: '+966500000003',
    identifierType: 'phone',
    isVerified: false,
    isProfileCompleted: false,
    role: UserRole.client,
  );
}
