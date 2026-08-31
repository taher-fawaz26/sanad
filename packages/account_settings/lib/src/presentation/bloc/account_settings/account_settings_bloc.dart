import 'package:account_settings/src/data/mappers/auth_account_settings_mapper.dart';
import 'package:account_settings/src/domain/entities/account_settings_entity.dart';
import 'package:account_settings/src/domain/enums/preferred_language.dart';
import 'package:account_settings/src/domain/usecases/account_settings_params.dart';
import 'package:account_settings/src/domain/usecases/refresh_account_profile_usecase.dart';
import 'package:account_settings/src/domain/usecases/update_account_settings_usecase.dart';
import 'package:auth/auth.dart' show SessionManager, UserType;
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'account_settings_event.dart';
part 'account_settings_state.dart';

/// Owns signed-in account settings.
///
/// Reads seed data from the auth session ([SessionManager]) — the same
/// snapshot that came back in the login/verify response — so the screen
/// renders instantly, then silently refreshes from the authoritative
/// persona-aware contract in the background (`GET /me` → `GET
/// /{persona}/profile`, via [RefreshAccountProfileUseCase]; see that class
/// for why — there is no `GET /account-settings` on the live backend). A
/// successful refresh is written straight back into the session via
/// [SessionManager.update], so every other consumer observes the fresh
/// value too, and the bloc re-seeds its state from that same session.
///
/// The background refresh fails silently (cached/session data stays on
/// screen) — a transient network hiccup on a passive refresh should never
/// surface an error banner over data that's still perfectly valid.
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
    required RefreshAccountProfileUseCase refreshAccountProfile,
    required SessionManager sessionManager,
  }) : _updateAccountSettings = updateAccountSettings,
       _refreshAccountProfile = refreshAccountProfile,
       _sessionManager = sessionManager,
       super(const AccountSettingsState()) {
    on<AccountSettingsLoaded>(_onLoaded);
    on<AccountSettingsRefreshed>(_onLoaded);
    on<AccountSettingsUpdated>(_onUpdated, transformer: droppable());
  }

  final UpdateAccountSettingsUseCase _updateAccountSettings;
  final RefreshAccountProfileUseCase _refreshAccountProfile;
  final SessionManager _sessionManager;

  /// Seeds from the session snapshot (instant, no network), then kicks off
  /// a background persona-profile refresh. Shared by the initial open and
  /// explicit refresh (pull-to-refresh, post phone/email change) — both want
  /// the same "show cached, then reconcile" behavior.
  Future<void> _onLoaded(
    AccountSettingsEvent event,
    Emitter<AccountSettingsState> emit,
  ) async {
    _seedFromSession(emit);
    await _refreshFromServer(emit);
  }

  void _seedFromSession(Emitter<AccountSettingsState> emit) {
    final seeded = _sessionManager.accountSettings?.toAccountSettingsEntity();
    emit(
      state.copyWith(
        loadStatus: RequestStatus.success,
        settings: seeded,
        clearFailure: true,
      ),
    );
  }

  /// Fetches the authoritative account settings and reconciles the session.
  /// Failures are swallowed — the screen already shows the cached session
  /// value, and a background-refresh error is not worth interrupting the
  /// user over.
  Future<void> _refreshFromServer(Emitter<AccountSettingsState> emit) async {
    final result = await _refreshAccountProfile(const NoParams()).run();
    await result.fold(
      (failure) async {},
      (settings) async {
        await _syncSession(settings);
        _seedFromSession(emit);
      },
    );
  }

  Future<void> _onUpdated(
    AccountSettingsUpdated event,
    Emitter<AccountSettingsState> emit,
  ) async {
    emit(
      state.copyWith(saveStatus: RequestStatus.loading, clearSaveFailure: true),
    );

    // Persona decides the endpoint: clients patch `clients/me`, everyone else
    // `account-settings`. A signed-in session always carries a `userType`; the
    // `?? client` fallback is unreachable in practice (a provider session
    // always resolves a concrete non-client type).
    final userType = _sessionManager.userType ?? UserType.client;
    final result = await _updateAccountSettings(event.params, userType).run();

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
