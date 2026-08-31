import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sanad_client/src/features/account_setup/account_setup_state.dart';

/// Owns the post-authentication setup flow's state, scoped to one
/// `ShellRoute` — see `client_router.dart`'s registration of
/// `AccountSetupRoutes`.
///
/// The account already has an authenticated session (established by verify);
/// this cubit persists the display name via `PATCH clients/me`
/// ([UpdateClientProfileUseCase]) and then refreshes the local session so the
/// name is reflected everywhere immediately. It deliberately does **not** use
/// `PATCH account-settings`, which the backend forbids for clients.
class AccountSetupCubit extends Cubit<AccountSetupState> {
  /// Creates an [AccountSetupCubit].
  AccountSetupCubit({
    required UpdateClientProfileUseCase updateProfile,
    required SessionManager sessionManager,
  }) : _updateProfile = updateProfile,
       _sessionManager = sessionManager,
       super(const AccountSetupState());

  final UpdateClientProfileUseCase _updateProfile;
  final SessionManager _sessionManager;

  /// Submits [name] to `PATCH clients/me`. On success refreshes the session
  /// with the returned profile and moves [AccountSetupState.status] to
  /// success; on failure preserves [name] so the user can retry.
  Future<void> submitName(String name) async {
    if (state.status == RequestStatus.loading) return;
    emit(
      state.copyWith(
        name: name,
        status: RequestStatus.loading,
        clearFailure: true,
      ),
    );

    final result = await _updateProfile(
      UpdateClientProfileParams(name: name),
    ).run();

    await result.match(
      (failure) async => emit(
        state.copyWith(status: RequestStatus.failure, failure: failure),
      ),
      (profile) async {
        await _refreshSession(profile);
        emit(state.copyWith(status: RequestStatus.success));
      },
    );
  }

  /// Writes the freshly-saved client profile back into the session so
  /// `SessionManager.displayName`/`email`/`phone` observe it. No-op when
  /// signed out (should not happen — this runs post-verify).
  Future<void> _refreshSession(ClientProfile profile) => _sessionManager.update(
    (session) => session.copyWith(
      accountSettings: AuthAccountSettingsModel(
        id: profile.id,
        name: profile.name,
        email: profile.email,
        phone: profile.phone,
        preferredLanguage: profile.preferredLanguage,
      ),
    ),
  );
}
