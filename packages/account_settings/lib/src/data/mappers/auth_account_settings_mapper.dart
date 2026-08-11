import 'package:account_settings/src/domain/entities/account_settings_entity.dart';
import 'package:account_settings/src/domain/enums/preferred_language.dart';
import 'package:auth/auth.dart'
    show AuthAccountSettingsEntity, AuthAccountSettingsModel;

/// Maps the `AuthAccountSettingsEntity` embedded in the auth session onto the
/// display entity this feature exposes to its UI.
///
/// The two types are intentionally distinct: `auth` owns the session-scoped
/// snapshot (nullable name/phone, wire-shaped `preferredLanguage: String`),
/// while `account_settings` owns the feature's own entity with typed
/// [PreferredLanguage] and its UI-friendly accessors. This adapter keeps the
/// packages independent — nothing in `auth` needs to know about
/// [AccountSettingsEntity] or [PreferredLanguage].
extension AuthAccountSettingsMapper on AuthAccountSettingsEntity {
  AccountSettingsEntity toAccountSettingsEntity() => AccountSettingsEntity(
    id: id,
    name: name,
    email: email,
    phone: phone,
    preferredLanguage: PreferredLanguage.fromApi(preferredLanguage),
  );
}

/// Reverse mapper — used after a successful PATCH to push the updated
/// account settings back into the session (via `SessionManager.update`).
///
/// Returns the concrete `AuthAccountSettingsModel` (not just the entity)
/// because [SessionStorage] casts session sub-objects to their model types
/// during serialisation.
extension AccountSettingsEntityToAuth on AccountSettingsEntity {
  AuthAccountSettingsModel toAuthAccountSettingsModel() =>
      AuthAccountSettingsModel(
        id: id,
        name: name,
        email: email,
        phone: phone,
        preferredLanguage: preferredLanguage.toApi(),
      );
}
