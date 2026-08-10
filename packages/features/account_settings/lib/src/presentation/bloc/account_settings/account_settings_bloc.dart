import 'package:account_settings/src/data/mappers/auth_account_settings_mapper.dart';
import 'package:account_settings/src/domain/entities/account_settings_entity.dart';
import 'package:account_settings/src/domain/enums/preferred_language.dart';
import 'package:account_settings/src/domain/usecases/account_settings_params.dart';
import 'package:account_settings/src/domain/usecases/update_account_settings_usecase.dart';
import 'package:auth/auth.dart' show SessionManager;
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'account_settings_event.dart';
part 'account_settings_state.dart';

/// Owns signed-in account settings.
///
/// Reads seed data from the auth session ([SessionManager]) — the same
/// snapshot that came back in the login/verify response — instead of firing
/// a network call on every open. There is no `GET /account-settings` on the
/// live backend (only `PATCH /account-settings` exists), so both the initial
/// [AccountSettingsLoaded] and the explicit [AccountSettingsRefreshed] (e.g.
/// pull-to-refresh, or after a phone/email change) reseed from the session
/// snapshot rather than hitting the server.
///
/// After a successful PATCH the updated entity is written back into the
/// session via [SessionManager.update] so every other consumer of the
/// session sees the fresh value immediately. Likewise, phone/email changes
/// write straight into the session (via `SessionManager.setPhone`/`setEmail`)
/// before [AccountSettingsRefreshed] is dispatched, so the reseed here always
/// observes the latest value.
class AccountSettingsBloc
    extends Bloc<AccountSettingsEvent, AccountSettingsState> {
  AccountSettingsBloc({
    required UpdateAccountSettingsUseCase updateAccountSettings,
    required SessionManager sessionManager,
  }) : _updateAccountSettings = updateAccountSettings,
       _sessionManager = sessionManager,
       super(const AccountSettingsState()) {
    on<AccountSettingsLoaded>(_onLoaded);
    on<AccountSettingsRefreshed>(_onRefreshed);
    on<AccountSettingsUpdated>(_onUpdated);
  }

  final UpdateAccountSettingsUseCase _updateAccountSettings;
  final SessionManager _sessionManager;

  /// Initial hub open — seeds from the session snapshot. No network call.
  ///
  /// If the session somehow lacks embedded accountSettings (should not
  /// happen for provider-owner accounts, but the wire is nullable) the state
  /// stays in `RequestStatus.success` with `settings: null`; the UI already
  /// tolerates that via the nullable getters on the state.
  void _onLoaded(
    AccountSettingsLoaded event,
    Emitter<AccountSettingsState> emit,
  ) {
    final seeded = _sessionManager.accountSettings?.toAccountSettingsEntity();
    emit(
      state.copyWith(
        loadStatus: RequestStatus.success,
        settings: seeded,
        clearFailure: true,
      ),
    );
  }

  /// Explicit refresh (pull-to-refresh, and after a phone/email change) —
  /// there is no `GET /account-settings` on the live backend, so this
  /// reseeds from the (already up to date) session snapshot, same as
  /// [_onLoaded].
  void _onRefreshed(
    AccountSettingsRefreshed event,
    Emitter<AccountSettingsState> emit,
  ) {
    final seeded = _sessionManager.accountSettings?.toAccountSettingsEntity();
    emit(
      state.copyWith(
        loadStatus: RequestStatus.success,
        settings: seeded,
        clearFailure: true,
      ),
    );
  }

  Future<void> _onUpdated(
    AccountSettingsUpdated event,
    Emitter<AccountSettingsState> emit,
  ) async {
    emit(
      state.copyWith(saveStatus: RequestStatus.loading, clearSaveFailure: true),
    );

    final result = await _updateAccountSettings(event.params).run();

    await result.fold(
      (failure) async => emit(
        state.copyWith(saveStatus: RequestStatus.failure, saveFailure: failure),
      ),
      (settings) async {
        emit(
          state.copyWith(
            saveStatus: RequestStatus.success,
            settings: settings,
          ),
        );
        await _syncSession(settings);
      },
    );
  }

  /// Push [settings] back into the session so every other consumer of
  /// `SessionManager.accountSettings` observes the fresh value.
  Future<void> _syncSession(AccountSettingsEntity settings) async {
    await _sessionManager.update(
      (current) => current.copyWith(
        accountSettings: settings.toAuthAccountSettingsModel(),
      ),
    );
  }
}
